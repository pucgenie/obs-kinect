Config = {}

local configLoader, err = load(io.readfile("config.lua"), "config.lua", "t", Config)
if (not configLoader) then
	error("config.lua failed to load: " .. err)
end

local configLoaded, err = pcall(configLoader)
if (not configLoaded) then
	error("config.lua failed to load: " .. err)
end

workspace("obs-kinect")
	configurations({ "Debug", "Release" })
	platforms({ "x86", "x86_64" })

	if (_ACTION) then
		location("build/" .. _ACTION)
	end

	-- Trigger premake before building, to automatically include new files (and premake changes)
	if (os.ishost("windows")) then
		local commandLine = "premake5.exe " .. table.concat(_ARGV, ' ')

		prebuildcommands("cd ../.. && " .. commandLine)
	end

	project("obs-kinect")
		kind("SharedLib")
		language("C++")
		cppdialect("C++17")
		targetdir("bin/%{cfg.buildcfg}/%{cfg.architecture}")

		files({ "src/**.hpp", "src/**.c", "src/**.cpp" })

		includedirs(assert(Config.libkinect.Include, "Missing kinect include dir"))
		includedirs(assert(Config.libobs.Include, "Missing obs include dir"))
		links("kinect20")
		links("obs")

		filter("action:vs*")
			defines("_ENABLE_ATOMIC_ALIGNMENT_FIX")

		filter("platforms:x86")
			architecture "x32"
			libdirs(assert(Config.libkinect.Lib32, "Missing kinect lib dir (x86)"))
			libdirs(assert(Config.libobs.Lib32, "Missing obs lib dir (x86)"))

		filter("platforms:x86_64")
			architecture "x64"
			libdirs(assert(Config.libkinect.Lib64, "Missing kinect lib dir (x86_64)"))
			libdirs(assert(Config.libobs.Lib64, "Missing obs lib dir (x86_64)"))

		filter("configurations:Debug")
			defines("DEBUG")
			symbols("On")

		filter("configurations:Release")
			defines("NDEBUG")
			omitframepointer("On")
			optimize("Full")
			symbols("On") -- Generate symbols in release too

		if (Config.CopyToDebug32) then
			filter("configurations:Debug", "architecture:x32")
				postbuildcommands({ "{COPY} %{cfg.buildtarget.abspath} " .. Config.CopyToDebug32 })
		end

		if (Config.CopyToDebug64) then
			filter("configurations:Debug", "architecture:x64")
				postbuildcommands({ "{COPY} %{cfg.buildtarget.abspath} " .. Config.CopyToDebug64 })
		end

		if (Config.CopyToRelease32) then
			filter("configurations:Release", "architecture:x32")
				postbuildcommands({ "{COPY} %{cfg.buildtarget.abspath} " .. Config.CopyToRelease32 })
		end

		if (Config.CopyToRelease64) then
			filter("configurations:Release", "architecture:x64")
				postbuildcommands({ "{COPY} %{cfg.buildtarget.abspath} " .. Config.CopyToRelease64 })
		end
