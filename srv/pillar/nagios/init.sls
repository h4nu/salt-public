# This pillar can be used when using nagios3 
nagios:
  server:
    admin_email: your@email.address 

    timeperiods:
      24x7:
        alias: 24 Hours A Day, 7 Days A Week
        sunday: 00:00-24:00
        monday: 00:00-24:00
        tuesday: 00:00-24:00
        wednesday: 00:00-24:00
        thursday: 00:00-24:00
        friday: 00:00-24:00
        saturday: 00:00-24:00
      workhours:
        alias: Standard Work Hours
        monday: 08:00-17:00
        tuesday: 08:00-17:00
        wednesday: 08:00-17:00
        thursday: 08:00-17:00
        friday: 08:00-17:00
      nonworkhours:
        alias: Non-Work Hours
        sunday: 00:00-24:00
        monday: 00:00-08:00,17:00-24:00
        tuesday: 00:00-08:00,17:00-24:00
        wednesday: 00:00-08:00,17:00-24:00
        thursday: 00:00-08:00,17:00-24:00
        friday: 00:00-08:00,17:00-24:00
        saturday: 00:00-24:00
      never:
        alias: Never

