page 8630 "Config. Tables"
{
    Caption = 'Config. Tables';
    Editable = false;
    PageType = List;
    SourceTable = "Config. Line";
    SourceTableView = SORTING("Line Type", "Parent Line No.")
                      WHERE("Line Type" = CONST(Table));

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Table ID"; "Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the table that you want to use for the line type. After you select a table ID from the list of objects in the lookup table, the name of the table is automatically filled in the Name field.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = NameEmphasize;
                    ToolTip = 'Specifies the name of the line type.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the table in the configuration worksheet. You can use the status information, which you provide, to help you in planning and tracking your work.';
                }
                field("Responsible ID"; "Responsible ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the Business Central user who is responsible for the configuration worksheet.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("Responsible ID");
                    end;
                }
                field(NoOfRecords; GetNoOfRecords)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'No. of Records';
                    ToolTip = 'Specifies how many records are created in connection with migration.';
                }
                field(Reference; Reference)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a url address. Use this field to provide a url address to a location that Specifies information about the table. For example, you could provide the address of a page that Specifies information about setup considerations that the solution implementer should consider.';
                }
                field("Package Code"; "Package Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the package associated with the configuration. The code is filled in when you use the Assign Package function to select the package for the line type.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Data)
            {
                Caption = 'Data';
                action("Show Data")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Data';
                    Image = Database;
                    ToolTip = 'Open the related page for the table to review the values in the table.';

                    trigger OnAction()
                    begin
                        ShowTableData;
                    end;
                }
                action("Copy Data")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Data';
                    Image = Copy;
                    ToolTip = 'Copy commonly used values from an existing company to a new one. For example, if you have a standard list of symptom codes that is common to all your service management implementations, you can copy the codes easily from one company to another.';

                    trigger OnAction()
                    begin
                        PAGE.RunModal(PAGE::"Copy Company Data");
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NameOnFormat;
    end;

    trigger OnOpenPage()
    begin
        FilterGroup(2);
        SetRange("Company Filter", CompanyName);
        FilterGroup(0);
    end;

    var
        [InDataSet]
        NameEmphasize: Boolean;

    local procedure NameOnFormat()
    begin
        NameEmphasize := "Line Type" <> "Line Type"::Table;
    end;
}

