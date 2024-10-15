#if not CLEAN20
page 31083 "Export Acc. Schedule Card"
{
    Caption = 'Export Acc. Schedule Card';
    PageType = Card;
    SourceTable = "Export Acc. Schedule";
    ObsoleteReason = 'The functionality will be removed and this page should not be used.';
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies name of intrastat journal lines';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies description of acc. schedule card';
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
    }

    actions
    {
        area(navigation)
        {
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
        }
        area(processing)
        {
            group("&Export Acc. Schedule")
            {
                Caption = '&Export Acc. Schedule';
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
