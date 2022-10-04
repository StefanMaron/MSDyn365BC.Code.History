page 8634 "Config. Package Table FactBox"
{
    Caption = 'Package Table';
    PageType = CardPart;
    SourceTable = "Config. Package Table";

    layout
    {
        area(content)
        {
            field("Package Code"; Rec."Package Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the ID for the table that is part of the migration process.';
            }
            field("Package Caption"; Rec."Package Caption")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies a name for the configuration package.';
            }
            field("No. of Package Records"; Rec."No. of Package Records")
            {
                ApplicationArea = Basic, Suite;
                StyleExpr = NoOfRecordsStyleTxt;
                ToolTip = 'Specifies the count of the number of configuration package records.';

                trigger OnDrillDown()
                begin
                    ShowPackageRecords(Show::All, "Dimensions as Columns");
                end;
            }
            field("No. of Package Errors"; Rec."No. of Package Errors")
            {
                ApplicationArea = Basic, Suite;
                StyleExpr = NoOfErrorsStyleTxt;
                ToolTip = 'Specifies the count of the number of package errors.';

                trigger OnDrillDown()
                begin
                    ShowPackageRecords(Show::Errors, "Dimensions as Columns");
                end;
            }
            field(NoOfDatabaseRecords; GetNoOfDatabaseRecords())
            {
                ApplicationArea = Basic, Suite;
                Caption = 'No. of Database Records';
                DrillDown = true;
                ToolTip = 'Specifies how many database records have been created in connection with the migration.';

                trigger OnDrillDown()
                begin
                    ShowDatabaseRecords();
                end;
            }
            field("No. of Fields Included"; Rec."No. of Fields Included")
            {
                ApplicationArea = Basic, Suite;
                DrillDown = true;
                DrillDownPageID = "Config. Package Fields";
                ToolTip = 'Specifies the count of the number of fields that are included in the migration table.';
            }
            field("No. of Fields Available"; Rec."No. of Fields Available")
            {
                ApplicationArea = Basic, Suite;
                DrillDown = true;
                DrillDownPageID = "Config. Package Fields";
                ToolTip = 'Specifies the count of the number of fields that are available in the migration table.';
            }
            field("Data Template"; Rec."Data Template")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the name of the data template that is being used as part of the migration process.';

                trigger OnLookup(var Text: Text): Boolean
                var
                    ConfigTemplateList: Page "Config. Template List";
                begin
                    Clear(ConfigTemplateList);
                    ConfigTemplateList.RunModal();
                end;
            }
            field("Processing Order"; Rec."Processing Order")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the number of the processing order. This is used to track the migration process.';
            }
            field(Filtered; Filtered)
            {
                ApplicationArea = Basic, Suite;
                DrillDown = true;
                DrillDownPageID = "Config. Package Filters";
                ToolTip = 'Specifies whether the package is filtered. This field is set depending on filter settings you have specified.';
            }
            field("Dimensions as Columns"; Rec."Dimensions as Columns")
            {
                ApplicationArea = Dimensions;
                ToolTip = 'Specifies whether dimensions should be displayed in columns. If you select No, then the dimensions are not displayed in any format.';
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        NoOfRecordsStyleTxt := SetFieldStyle(FieldNo("No. of Package Records"));
        NoOfErrorsStyleTxt := SetFieldStyle(FieldNo("No. of Package Errors"));
    end;

    trigger OnOpenPage()
    begin
        SetFilter("Company Filter (Source Table)", '%1', CompanyName);
    end;

    var
        [InDataSet]
        NoOfRecordsStyleTxt: Text;
        [InDataSet]
        NoOfErrorsStyleTxt: Text;
        Show: Option Records,Errors,All;
}

