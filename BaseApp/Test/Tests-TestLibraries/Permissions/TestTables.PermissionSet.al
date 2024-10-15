permissionset 132217 "Test Tables"
{
    Assignable = true;

    IncludedPermissionSets = "System Application Test Tables",
                             "Local Test Tables";

    Permissions = tabledata "All-Keys Type" = RIMD,
                  tabledata "Amount Auto Format Test Table" = RIMD,
                  tabledata "Asm. Availability Test Buffer" = RIMD,
                  tabledata "Comparison Type" = RIMD,
                  tabledata "Data Mig. Item Staging Table" = RIMD,
                  tabledata "Data Type Buffer" = RIMD,
                  tabledata "Delta watch" = RIMD,
                  tabledata "Detailed Entry With Global Dim" = RIMD,
                  tabledata "Dtld. Entry With Global Dim 2" = RIMD,
                  tabledata "Enabled Test Codeunit" = RIMD,
                  tabledata "Enabled Test Method" = RIMD,
                  tabledata ExchangeContactMock = RIMD,
                  tabledata "Feature Label Data" = RIMD,
                  tabledata "File Commits" = RIMD,
                  tabledata "Generate Test Data Line" = RIMD,
                  tabledata "Job Queue Sample Logging" = RIMD,
                  tabledata "Master Data Setup Sample" = RIMD,
                  tabledata "Mock Master Table" = RIMD,
                  tabledata "OData Test Metrics" = RIMD,
                  tabledata "Prediction Data" = RIMD,
                  tabledata "Reference data" = RIMD,
                  tabledata "Reference data - field list" = RIMD,
                  tabledata "Reference Data Log" = RIMD,
                  tabledata Snapshot = RIMD,
                  tabledata "Table AutoIncrement Out Of PK" = RIMD,
                  tabledata "Table With Default Dim" = RIMD,
                  tabledata "Table With Dimension Set ID" = RIMD,
                  tabledata "Table With Dim Flowfilter" = RIMD,
                  tabledata "Table With Link To G/L Account" = RIMD,
                  tabledata "Table With PK 16 Fields" = RIMD,
                  tabledata "Table With Wrong Relation" = RIMD,
                  tabledata "Tainted Table" = RIMD,
                  tabledata "Test Data Exch. Dest Table" = RIMD,
                  tabledata "Test Integration Table" = RIMD,
                  tabledata "Test Table with large field" = RIMD,
                  tabledata "Update Parent Fact Line" = RIMD,
                  tabledata "Update Parent Header" = RIMD,
                  tabledata "Update Parent Line" = RIMD,
                  tabledata "Update Parent Register Line" = RIMD,
                  tabledata "Watch Customer" = RIMD,
                  tabledata "Watch Customer Ledger Entry" = RIMD,
                  tabledata "Watch Vendor" = RIMD,
                  tabledata "Watch Vendor Ledger Entry" = RIMD,
                  tabledata "Webhook Notification Trigger" = RIMD,
                  tabledata "Webhook Test Metrics" = RIMD;
}