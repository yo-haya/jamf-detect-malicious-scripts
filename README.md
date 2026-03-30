# HOW TO USE
## Setup: Extension attributes
1. Open Jamf Pro Console
2. Open `Settings > Extension attributes(設定 > 拡張属性)`
3. Click `+New(＋新規)`
4. Select `Input type: Script(入力タイプ: スクリプト)`
5. Copy & Paste a shell script(text) to Script field at Jamf Pro
6. Save it with a name of your choice. (e.g. `DetectedMaliciousPkgLiteLLM`)

## Setup: Smart computer groups
1. Open Jamf Pro Console
2. Open `Computers > Smart computer groups(コンピュータ > スマートコンピュータグループ)`
3. Click `+New(＋新規)`
4. Set the criteria as follows(The following is a sample):
    ```
    ( DetectedMaliciousPkgLiteLLM is not ""
    and DetectedMaliciousPkgLiteLLM is not "Not Detected")
    or ( DetectedMaliciousPkgTelnyx is not ""
    and DetectedMaliciousPkgTelnyx is not "Not Detected")
    or ( DetectedMaliciousScriptsLiteLLM is not ""
    and DetectedMaliciousScriptsLiteLLM is not "Not Detected")
    ```
5. Save it with a name of your choice. (e.g. `Alert - Detected Malicious Packages`)

#This setting will display a list of computers that require attention.
