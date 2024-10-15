#if not CLEAN20
page 31084 "Export Acc. Schedule List"
{
    Caption = 'Export Acc. Schedule List';
    CardPageID = "Export Acc. Schedule Card";
    Editable = false;
    PageType = List;
    SourceTable = "Export Acc. Schedule";
    ObsoleteReason = 'The functionality will be removed and this page should not be used.';
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';

    layout
    {
        area(content)
        {
            repeater(Control1220005)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies name of file';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies description of acc. schedule list';
                }
                field("Account Schedule Name"; Rec."Account Schedule Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the account schedule.';
                }
                field("Column Layout Name"; Rec."Column Layout Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the column layout that you want to use in the window.';
                }
                field("Show Amts. in Add. Curr."; Rec."Show Amts. in Add. Curr.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies amounts in add. currency.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220010; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220009; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Export Acc. Schedule")
            {
                Caption = '&Export Acc. Schedule';
                action("&Filters")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Filters';
                    Image = EditFilter;
                    ToolTip = 'Specifies acc. Schedule  filtrs';

                    trigger OnAction()
                    begin
                        ShowFilterTable();
                    end;
                }
                action("E&xport to Excel")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'E&xport to Excel';
                    Ellipsis = true;
                    Image = ExportToExcel;
                    ToolTip = 'Allows to export account schedule into excel.';

                    trigger OnAction()
                    var
                        FilteredAccSchedExport: Report "Filtered Acc. Schedule Export";
                    begin
                        FilteredAccSchedExport.SetParameter(Rec);
                        FilteredAccSchedExport.Run();
                    end;
                }
            }
        }
    }
}
#endif
