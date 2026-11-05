# Single source for browser choices: command, window flags and .desktop file.
# Kept outside the module tree so option enums can import it without creating
# a _module.args/config cycle.
{
  browsers = {
    chromium = {
      command = "chromium";
      newWindow = "--new-window";
      privateWindow = "--incognito";
      desktopFile = "chromium-browser.desktop";
    };
    google-chrome = {
      command = "google-chrome-stable";
      newWindow = "--new-window";
      privateWindow = "--incognito";
      desktopFile = "google-chrome.desktop";
    };
    librewolf = {
      command = "librewolf";
      newWindow = "--new-window";
      privateWindow = "--private-window";
      desktopFile = "librewolf.desktop";
    };
  };
}
