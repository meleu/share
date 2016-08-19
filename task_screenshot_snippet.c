// RetroArch screenshots with the ROM name
   if (settings->auto_screenshot_filename)
   {
      time_t cur_time;
      time(&cur_time);
      char format[PATH_MAX_LENGTH] = {0};

      snprintf(format, sizeof(format),
            "%s-%%Y%%m%%d-%%H%%M%%S.", path_basename(global_name_base));
      strftime(shotname, sizeof(shotname), format, localtime(&cur_time));
      strlcat(shotname, IMG_EXT, sizeof(shotname));
   }
   else
   {
      snprintf(shotname, sizeof(shotname),"%s.png", path_basename(global_name_base));
   }
   fill_pathname_join(filename, folder, shotname, sizeof(filename));
