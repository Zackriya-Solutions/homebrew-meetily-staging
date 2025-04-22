cask "meetily" do
  version "0.0.4"
  sha256 "87f01fbdc3ab39af881408cd67564e27d3547df3feb07a3b73481a9ff1704d62"
  url "https://github.com/Zackriya-Solutions/meeting-minutes/releases/download/v#{version}/dmg_darwin_arch64.zip"
  name "Meetily"
  desc "Meeting transcription and analysis application"
  homepage "https://github.com/Zackriya-Solutions/meeting-minutes"

  depends_on formula: "meetily-backend"
  depends_on macos: ">= :monterey"
  depends_on arch: :arm64

  container nested: "dmg/meeting-minutes-frontend_0.1.0_aarch64.dmg"
  
  app "meeting-minutes-frontend.app"
  
  postflight do
    # Clear extended attributes to avoid security/quarantine issues
    system_command "/usr/bin/xattr",
                   args: ["-c", "/Applications/meeting-minutes-frontend.app"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Application Support/Meetily",
    "~/Library/Preferences/com.zackriya.meetily.plist",
    "~/Library/Saved Application State/com.zackriya.meetily.savedState",
    "~/Library/Logs/Meetily"
  ]

  caveats do
    <<~EOS
      Meetily requires the backend server to be running.
      
      To start the backend server:
        meetily-server
      
      The frontend will automatically connect to the backend at:
        http://localhost:5167
    EOS
  end
end
