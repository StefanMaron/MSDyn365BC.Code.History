page 11603 "BAS Calc. Schedule List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'BAS Calculation Sheets';
    CardPageID = "BAS Calculation Sheet";
    Editable = false;
    PageType = List;
    SourceTable = "BAS Calculation Sheet";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(A1; A1)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the BAS document number that is provided by the Australian Tax Office (ATO).';
                }
                field("BAS Version"; "BAS Version")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the version number of the BAS document.';
                }
                field(A2; A2)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(A3; A3)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date of the Business Activity Statement (BAS) that is provided by the Australian Tax Office (ATO).';
                }
                field(A4; A4)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(A5; A5)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(A6; A6)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(Exported; Exported)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the file has been exported.';
                }
                field("User Id"; "User Id")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the person who performs the import or export of the XML file.';
                }
                field("Date of Export"; "Date of Export")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the file was exported.';
                }
                field("Time of Export"; "Time of Export")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the time that the file was exported.';
                }
                field("File Name"; "File Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the file.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Import)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import';
                    Ellipsis = true;
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Exports the XML field IDs from the BAS - XML Field IDs Setup window.';

                    trigger OnAction()
                    begin
                        BASImportExport.SetBASCalcSheetRecord(Rec);
                        BASImportExport.SetDirection(0);
                        BASImportExport.RunModal;
                        BASImportExport.ReturnRecord(Rec);
                        Clear(BASImportExport);
                    end;
                }
                action(Update)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update';
                    Ellipsis = true;
                    Image = Refresh;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Start the process of submitting an update of your business activity statement.';

                    trigger OnAction()
                    begin
                        BASMngmt.UpdateBAS(Rec);
                        Clear(BASMngmt);
                    end;
                }
                action(Export)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'E&xport';
                    Ellipsis = true;
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Exports the XML field IDs to the BAS - XML Field IDs Setup window.';

                    trigger OnAction()
                    begin
                        BASImportExport.SetBASCalcSheetRecord(Rec);
                        BASImportExport.SetDirection(1);
                        BASImportExport.RunModal;
                        BASImportExport.ReturnRecord(Rec);
                        Clear(BASImportExport);
                    end;
                }
                separator(Action150004)
                {
                    Caption = '';
                }
                action(CalculateGSTSettlement)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculate GST Settlement';
                    Image = CalculateSalesTax;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Start the process of calculating the GST settlement.';

                    trigger OnAction()
                    begin
                        BASCalcSheet.Reset;
                        BASCalcSheet.SetRange(A1, A1);
                        BASCalcSheet.SetRange("BAS Version", "BAS Version");
                        REPORT.RunModal(REPORT::"Calculate GST Settlement", true, false, BASCalcSheet);
                    end;
                }
                action("GST Purchase Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'GST Purchase Entries';
                    RunObject = Page "GST Purchase Entries";
                    ToolTip = 'Start the process of creating the GST Purchase report.';
                }
                action("GST Sales Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'GST Sales Entries';
                    RunObject = Page "GST Sales Entries";
                    ToolTip = 'Start the process of creating the GST Sales report.';
                }
            }
        }
        area(reporting)
        {
            action("GST Purchase Report")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'GST Purchase Report';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "GST Purchase Report";
                ToolTip = 'Start the process of creating the GST Purchase report.';
            }
            action("GST Sales Report")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'GST Sales Report';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "GST Sales Report";
                ToolTip = 'Start the process of creating the GST Sales report.';
            }
        }
    }

    var
        BASCalcSheet: Record "BAS Calculation Sheet";
        BASImportExport: Report "BAS - Import/Export";
        BASMngmt: Codeunit "BAS Management";
}

