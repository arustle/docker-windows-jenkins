# this script is based off of the shell script from https://github.com/jenkinsci/docker/blob/master/install-plugins.sh

param([String] $pluginFilePath)

Add-Type -assembly "System.IO.Compression.FileSystem"

$env:JENKINS_UC_DOWNLOAD="https://updates.jenkins-ci.org/download"
$env:JENKINS_WAR="C:\\jenkins.war"

# . /usr/local/bin/jenkins-support

$REF_DIR="C:\\jenkins\\plugins"
# FAILED="$env:REF_DIR/failed-plugins.txt"


function Get-bundledPlugins() {
    # if [ -f "$JENKINS_WAR" ]
    # then
    #     TEMP_PLUGIN_DIR=/tmp/plugintemp.$$
    #     for i in $(jar tf "$JENKINS_WAR" | grep -E '[^detached-]plugins.*\..pi' | sort)
    #     do
    #         rm -fr $TEMP_PLUGIN_DIR
    #         mkdir -p $TEMP_PLUGIN_DIR
    #         PLUGIN=$(basename "$i"|cut -f1 -d'.')
    #         (cd $TEMP_PLUGIN_DIR;jar xf "$JENKINS_WAR" "$i";jar xvf "$TEMP_PLUGIN_DIR/$i" META-INF/MANIFEST.MF >/dev/null 2>&1)
    #         VER=$(grep -E -i Plugin-Version "$TEMP_PLUGIN_DIR/META-INF/MANIFEST.MF"|cut -d: -f2|sed 's/ //')
    #         echo "$PLUGIN:$VER"
    #     done
    #     rm -fr $TEMP_PLUGIN_DIR
    # else
    #     echo "war not found, installing all plugins: $JENKINS_WAR"
    # fi
}

function Get-installedPlugins () {
    # for f in "$REF_DIR"/*.jpi; do
    #     echo "$(basename "$f" | sed -e 's/\.jpi//'):$(get_plugin_version "$f")"
    # done
    Get-ChildItem $REF_DIR -Filter *.jpi | 
    ForEach-Object {
        $filename = $_
        Write-Output ($filename -replace ".jpi", "")        
    }
}

function Get-jenkinsMajorMinorVersion() {
    return ""
    # if ($env:JENKINS_WAR) {
    #     local version major minor
    #     version="$(java -jar "$JENKINS_WAR" --version)"
    #     major="$(echo "$version" | cut -d '.' -f 1)"
    #     minor="$(echo "$version" | cut -d '.' -f 2)"
    #     echo "$major.$minor"
    # } else {

    # }
}


function Get-resolveDependencies($outputSpacing,$plugin) {
    if (!$plugin) {
        return
    }
    $jpi = Get-ArchiveFilename $plugin

    $dependencies = ''
    $manifestItems = (Read-FileInZip $jpi "META-INF/MANIFEST.MF") -replace "\r\n ", "" -split '\n'
    foreach ($item in $manifestItems ) {
        if ($item -match '^Plugin-Dependencies') {
            $dependencies = $item -replace 'Plugin-Dependencies:', ''
        } 
    }

    if (!$dependencies) {
        Write-Output "$outputSpacing > $plugin has no dependencies"
        return
    }

    Write-Output " > $plugin depends on $dependencies"

    $depPlugins = $dependencies -split ','
    foreach ($depPlugin in $depPlugins ) {
        $depPlugin=$depPlugin.Trim()
        $newOutputSpacing = "$outputSpacing    "
        $pluginInstalled=""
        if ($depPlugin -match 'optional') {
            Write-Output "Skipping optional dependency $plugin"
        } else {
            $depPluginName = ($depPlugin -split ':')[0]
            $depPluginVersion = ($depPlugin -split ':')[1]
            if (!$depPluginName) {
                $depPluginName = $depPlugin
            }

            foreach ($xPlugin in $bundledPlugins ) {
                if ($xPlugin -match $depPluginName) {
                    $pluginInstalled = $xPlugin
                }
            }

            if (!$pluginInstalled) {
                Get-installedPlugins |
                    ForEach-Object {
                        $filename = $_
                        if ($_ -match $depPluginName) {
                            $pluginInstalled = $filename
                        } 
                    }

                # foreach ($xPlugin in Get-installedPlugins ) {
                #     if ($xPlugin -match $depPluginName) {
                #         $pluginInstalled = $xPlugin
                #     }
                # }
            }
            if ($pluginInstalled) {
                $versionInstalled = Get-versionFromPlugin $pluginInstalled
                $minVersion = Get-versionFromPlugin $depPlugin
                Write-Output "$versionInstalled < $minVersion"
                if ($versionInstalled -lt $minVersion) {
                    Write-Output "$newOutputSpacing Upgrading bundled dependency $depPlugin ($minVersion > $versionInstalled)"
                    Get-download $newOutputSpacing $depPluginName
                } else {
                    Write-Output "$newOutputSpacing Skipping already installed dependency $depPlugin ($minVersion <= $versionInstalled)"
                }
            } else {
                Get-download $newOutputSpacing $depPluginName $depPluginVersion
            }
        }
    }

}

function Get-versionFromPlugin($plugin) {
    $parts = $plugin -split ':'
    if ($parts[1]) {
        return $parts[1];
    }
    
    return "latest"

}

function Get-checkIntegrity($plugin) {
    return 1
    # $jpi = getArchiveFilename($plugin)

    # unzip -t -qq "$jpi" >/dev/null
    # return $?
}

function Get-doDownload($outputSpacing,$plugin, $version, $url) {
    $jpi = Get-ArchiveFilename $plugin

    # If plugin already exists and is the same version do not download
    # if test -f "$jpi" && unzip -p "$jpi" META-INF/MANIFEST.MF | tr -d '\r' | grep "^Plugin-Version: ${version}$" > /dev/null; then
    #     echo "Using provided plugin: $plugin"
    #     return 0
    # fi

    # if [[ -n $url ]] ; then
    #     echo "Will use url=$url"
    # elif [[ "$version" == "latest" && -n "$JENKINS_UC_LATEST" ]]; then
    #     # If version-specific Update Center is available, which is the case for LTS versions,
    #     # use it to resolve latest versions.
    #     url="$JENKINS_UC_LATEST/latest/${plugin}.hpi"
    # elif [[ "$version" == "experimental" && -n "$JENKINS_UC_EXPERIMENTAL" ]]; then
    #     # Download from the experimental update center
    #     url="$JENKINS_UC_EXPERIMENTAL/latest/${plugin}.hpi"
    # elif [[ "$version" == incrementals* ]] ; then
    #     # Download from Incrementals repo: https://jenkins.io/blog/2018/05/15/incremental-deployment/
    #     # Example URL: https://repo.jenkins-ci.org/incrementals/org/jenkins-ci/plugins/workflow/workflow-support/2.19-rc289.d09828a05a74/workflow-support-2.19-rc289.d09828a05a74.hpi
    #     local groupId incrementalsVersion
    #     # add a trailing ; so the \n gets added to the end
    #     readarray -t "-d;" arrIN <<<"${version};";
    #     unset 'arrIN[-1]';
    #     groupId=${arrIN[1]}
    #     incrementalsVersion=${arrIN[2]}
    #     url="${JENKINS_INCREMENTALS_REPO_MIRROR}/$(echo "${groupId}" | tr '.' '/')/${plugin}/${incrementalsVersion}/${plugin}-${incrementalsVersion}.hpi"
    # else
    #     JENKINS_UC_DOWNLOAD=${JENKINS_UC_DOWNLOAD:-"$JENKINS_UC/download"}
    #     url="$env:JENKINS_UC_DOWNLOAD/plugins/$plugin/$version/${plugin}.hpi"
    # fi


    # $plugin="blueocean"
    # $version="1.19.0"
    # $jpi="c:\jenkins\aaa\$plugin.jpi"
    
    $url="$env:JENKINS_UC_DOWNLOAD/plugins/$plugin/$version/${plugin}.hpi"

    Write-Output "$outputSpacing Downloading plugin: $plugin from $url"
    $webClient.DownloadFile($url, $jpi)

    # We actually want to allow variable value to be split into multiple options passed to curl.
    # This is needed to allow long options and any options that take value.
    # shellcheck disable=SC2086
    # retry_command curl ${CURL_OPTIONS:--sSfL} --connect-timeout "${CURL_CONNECTION_TIMEOUT:-20}" --retry "${CURL_RETRY:-3}" --retry-delay "${CURL_RETRY_DELAY:-0}" --retry-max-time "${CURL_RETRY_MAX_TIME:-60}" "$url" -o "$jpi"
    # return $?
    return 1
}


function Get-ArchiveFilename($plugin) {
    return "$REF_DIR/${plugin}.jpi"
}


# function Get-LockFile($plugin) {
#     return "$env:REF_DIR/$plugin.lock";
# }


function Read-FileInZip($ZipFilePath, $FilePathInZip) {
    try {
        if (![System.IO.File]::Exists($ZipFilePath)) {
            throw "Zip file ""$ZipFilePath"" not found."
        }

        $Zip = [System.IO.Compression.ZipFile]::OpenRead($ZipFilePath)
        $ZipEntries = [array]($Zip.Entries | where-object {
                return $_.FullName -eq $FilePathInZip
            });
        if (!$ZipEntries -or $ZipEntries.Length -lt 1) {
            throw "File ""$FilePathInZip"" couldn't be found in zip ""$ZipFilePath""."
        }
        if (!$ZipEntries -or $ZipEntries.Length -gt 1) {
            throw "More than one file ""$FilePathInZip"" found in zip ""$ZipFilePath""."
        }

        $ZipStream = $ZipEntries[0].Open()

        $Reader = [System.IO.StreamReader]::new($ZipStream)
        return $Reader.ReadToEnd()
    }
    finally {
        if ($Reader) { $Reader.Dispose() }
        if ($Zip) { $Zip.Dispose() }
    }
}


function Get-download($outputSpacing,$pluginId,$v,$lock,$u) {
    $plugin=$pluginId
    $version=$v
    if (!$v) {
        $version = 'latest'
    }
    $ignoreLockFile=$lock
    $url=$u
    # lock=Get-LockFile($plugin)

    # if [[ $ignoreLockFile ]] || mkdir "$lock" &>/dev/null; then
    #     if ! doDownload "$plugin" "$version" "$url"; then
    #         # some plugin don't follow the rules about artifact ID
    #         # typically: docker-plugin
    #         originalPlugin="$plugin"
    #         plugin="${plugin}-plugin"
    #         if ! doDownload "$plugin" "$version" "$url"; then
    #             echo "Failed to download plugin: $originalPlugin or $plugin" >&2
    #             echo "Not downloaded: ${originalPlugin}" >> "$FAILED"
    #             return 1
    #         fi
    #     fi

    #     if ! checkIntegrity "$plugin"; then
    #         echo "Downloaded file is not a valid ZIP: $(getArchiveFilename "$plugin")" >&2
    #         echo "Download integrity: ${plugin}" >> "$FAILED"
    #         return 1
    #     fi

    #     resolveDependencies "$plugin"
    # fi


    if (!(Get-doDownload $outputSpacing $plugin $version $url )) {
        # some plugin don't follow the rules about artifact ID
        # typically: docker-plugin
        $originalPlugin=$plugin
        $plugin="${plugin}-plugin"
        if (!(Get-doDownload $outputSpacing $plugin $version $url)) {
            Write-Output "Failed to download plugin: $originalPlugin or $plugin"
            # Write-Output "Not downloaded: ${originalPlugin}" >> "$FAILED"
            return 1
        }
    }

    if (!(Get-checkIntegrity $plugin )) {
        $archiveName = Get-ArchiveFilename $plugin
        Write-Output "Downloaded file is not a valid ZIP: $archiveName)"
        # Write-Output "Download integrity: ${plugin}" >> "$FAILED"
        return 1
    }


    Get-resolveDependencies $outputSpacing $plugin

}










Write-Output "File: "$pluginFileName

New-Item -ItemType Directory -Path "c:\jenkins" -Name "plugins"

# empty array
$plugins = @()

# web client for downloading files
$webClient = New-Object System.Net.WebClient

# Read plugins from stdin or from the command line arguments
foreach($line in Get-Content $pluginFilePath) {
    # Write-Output "Name: $line"
    
    # Remove leading/trailing spaces, comments, and empty lines
    $plugin = $line
    if ($plugin -gt 0) {
        $plugins += ,$plugin
    }
}


Write-Output "Analyzing war $env:JENKINS_WAR..."
$bundledPlugins=Get-bundledPlugins




Write-Output "Registering preinstalled plugins..."
$installedPlugins=Get-installedPlugins



# $jenkinsVersion=Get-jenkinsMajorMinorVersion




Write-Output "Downloading plugins..."
foreach ($plugin in $plugins) {
    $reg='^([^:]+):?([^:]+)?:?([^:]+)?:?(http.+)?'
    if ($plugin -match $reg) {
        $pluginId=$matches[1]
        $version=$matches[2]
        $lock=$matches[3]
        $url=$matches[4]

        # if ($pluginId) {
        #     $pluginId=$pluginId.Trim()
        # }
        # if ($version) {
        #     $version=$version.Trim()
        # }
        # if ($lock) {
        #     $lock=$lock.Trim()
        # }
        # if ($url) {
        #     $url=$url.Trim()
        # }


        Write-Output "`PLUGIN: $pluginId, $version, $lock, $url"
        Get-download "" $pluginId $version $lock $url
        Write-Output "`n`n"
    } else {
        Write-Output "Skipping the line '${plugin}' as it does not look like a reference to a plugin"
    }
}

