cask "meetily" do
    version "0.0.6"
    sha256 "fa5708fed0a9f03db524f26a2190dfd72a636e731414416710a7f63b05466aa6"
    url "https://github.com/Zackriya-Solutions/meeting-minutes/releases/download/test-v0.0.6/dmg_test_0.0.6.zip"
    name "Meetily"
    desc "Meeting transcription and analysis application"
    homepage "https://github.com/Zackriya-Solutions/meeting-minutes"
  
    depends_on macos: ">= :monterey"
    depends_on arch: :arm64
  
    container nested: "dmg/meetily-frontend_0.0.6_aarch64.dmg"
    
    app "meetily-frontend.app"
    
    postflight do
      # Clear extended attributes to avoid security/quarantine issues
      system_command "/usr/bin/xattr",
                     args: ["-c", "/Applications/meetily-frontend.app"],
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
        Meetily now includes an integrated backend server!
        
        Simply launch the application - no separate backend setup required.
        The integrated backend will start automatically with the frontend.
      EOS
    end
  end
  