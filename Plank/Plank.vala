//  
//  Copyright (C) 2011 Robert Dyer, Rico Tzschichholz
// 
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
// 
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
// 
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
// 

using Gtk;
using Unique;

using Plank.Factories;
using Plank.Services;
using Plank.Services.Windows;
using Plank.Widgets;

namespace Plank
{
	public class Plank : AbstractMain
	{
		public static int main (string[] args)
		{
			var main_class = new Plank ();
			Factory.init (main_class, new ItemFactory ());
			return main_class.start (args);
		}
		
		private int start (string[] args)
		{
			// set program name
			prctl (15, "plank", 0, 0, 0);
			
			Posix.signal(Posix.SIGINT, sig_handler);
			Posix.signal(Posix.SIGTERM, sig_handler);
			
			Logger.initialize ("Plank");
			Logger.DisplayLevel = LogLevel.INFO;
			Logger.info<Plank> ("Plank version: %s".printf (Build.VERSION));
			utsname un = utsname ();
			uname (un);
			Logger.info<Plank> ("Kernel version: %s".printf ((string) un.release));
			Logger.DisplayLevel = LogLevel.WARN;
			
			// parse commandline options
			var context = new OptionContext ("");
			
			context.add_main_entries (options, null);
			context.add_group (Gtk.get_option_group (false));
			
			try {
				context.parse (ref args);
			} catch { }
			
			Intl.bindtextdomain ("plank", Build.DATADIR + "/locale");
			
			if (!Thread.supported ()) {
				Logger.fatal<Plank> ("Problem initializing thread support.");
				return -1;
			}
			Gdk.threads_init ();
			Gtk.init (ref args);
			
			// ensure only one instance
			if (new App ("net.launchpad.plank", null).is_running) {
				Logger.fatal<Plank> ("Exiting because another instance is already running.");
				return -2;
			}
			
			set_options ();
			
			Paths.initialize ("plank");
			WindowControl.initialize ();
			
			var app = new DockWindow ();
			app.show_all ();
			
			Gdk.threads_enter ();
			Gtk.main ();
			Gdk.threads_leave ();
			
			return 0;
		}
		
		public override void quit ()
		{
			Gtk.main_quit ();
		}
		
		public override void show_about ()
		{
			var dlg = new AboutDialog ();
			
			dlg.set_program_name ("Plank");
			dlg.set_version (Build.VERSION);
			dlg.set_logo_icon_name ("plank");
			
			dlg.set_comments ("Plank. Stupidly simple.");
			dlg.set_copyright ("Copyright © 2011 Plank Developers");
			dlg.set_website ("https://launchpad.net/plank");
			dlg.set_website_label ("Website");
			
			dlg.set_authors ({
				"Robert Dyer <robert@go-docky.com>",
				"Rico Tzschichholz <rtz@go-docky.com>",
				"Michal Hruby <michal.mhr@gmail.com>"
			});
			dlg.set_documenters ({
				"Robert Dyer <robert@go-docky.com>"
			});
			dlg.set_artists ({
				"Daniel Foré <bunny@go-docky.com>"
			});
			dlg.set_translator_credits ("");
			
			dlg.show_all ();
			dlg.response.connect (() => {
				dlg.hide_all ();
				dlg.destroy ();
			});
		}
	}
}
