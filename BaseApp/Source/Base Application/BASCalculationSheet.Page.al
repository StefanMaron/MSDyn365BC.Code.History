page 11601 "BAS Calculation Sheet"
{
    Caption = 'BAS Calculation Sheet';
    PageType = Card;
    Permissions = TableData "BAS Calculation Sheet" = rm;
    SourceTable = "BAS Calculation Sheet";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(A1; A1)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
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
                field(A2a; A2a)
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
                field("BAS Setup Name"; "BAS Setup Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the Business Activity Statement (BAS) setup information that was used to populate the BAS calculation sheet.';
                }
                field(Exported; Exported)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the file has been exported.';
                }
                field(Updated; Updated)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the field is checked when the user has run the Update function.';
                }
                field(Consolidated; Consolidated)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if there has been a consolidation performed on the nominated entity required for reporting VAT.';
                }
                field("Group Consolidated"; "Group Consolidated")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the BAS was included in the group consolidated BAS.';
                }
                field(Settled; Settled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the corresponding BAS calculation sheet report was settled after running the calculate VAT settlement function.';
                }
            }
            group(Totals)
            {
                Caption = 'Totals';
                field("1A"; "1A")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName("1A"));
                    end;
                }
                field("1C"; "1C")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName("1C"));
                    end;
                }
                field("1E"; "1E")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName("1E"));
                    end;
                }
                field("4"; "4")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName("4"));
                    end;
                }
                field("1B"; "1B")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName("1B"));
                    end;
                }
                field("1D"; "1D")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName("1D"));
                    end;
                }
                field("1F"; "1F")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName("1F"));
                    end;
                }
                field("1G"; "1G")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName("1G"));
                    end;
                }
                field("1H"; "1H")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field("5B"; "5B")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName("5B"));
                    end;
                }
                field("6B"; "6B")
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName("6B"));
                    end;
                }
                field("7C"; "7C")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field("7D"; "7D")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
            }
            group(GST)
            {
                Caption = 'GST';
                field(G1; G1)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName(G1));
                    end;
                }
                field(G2; G2)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName(G2));
                    end;
                }
                field(G3; G3)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName(G3));
                    end;
                }
                field(G4; G4)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName(G4));
                    end;
                }
                field(G7; G7)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName(G7));
                    end;
                }
                field(G9; G9)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(G10; G10)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName(G10));
                    end;
                }
                field(G11; G11)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName(G11));
                    end;
                }
                field(G13; G13)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName(G13));
                    end;
                }
                field(G14; G14)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName(G14));
                    end;
                }
                field(G15; G15)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName(G15));
                    end;
                }
                field(G18; G18)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName(G18));
                    end;
                }
                field(G20; G20)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(G22; G22)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(G24; G24)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
            }
            group("Amounts Withheld")
            {
                Caption = 'Amounts Withheld';
                field(W1; W1)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName(W1));
                    end;
                }
                field(W2; W2)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName(W2));
                    end;
                }
                field(W3; W3)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName(W3));
                    end;
                }
                field(W4; W4)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName(W4));
                    end;
                }
            }
            group("Income Tax Installment")
            {
                Caption = 'Income Tax Installment';
                field(T1; T1)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';

                    trigger OnDrillDown()
                    begin
                        BASEntryDrillDown(FieldName(T1));
                    end;
                }
                field(T2; T2)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(T3; T3)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(T4; T4)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(T8; T8)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(T9; T9)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
            }
            group("FBT Installment")
            {
                Caption = 'FBT Installment';
                field(F1; F1)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(F2; F2)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
                field(F4; F4)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                    ToolTip = 'Specifies a value field according to the BAS instruction manual.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&BAS Calculation Sheet")
            {
                Caption = '&BAS Calculation Sheet';
                Image = CalculateVAT;
                action("BAS Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'BAS Setup';
                    Image = VATStatement;
                    ToolTip = 'View or edit the business activity statement (BAS) configuration information.';

                    trigger OnAction()
                    var
                        BASSetup: Record "BAS Setup";
                        BASSetupForm: Page "BAS Setup";
                    begin
                        TestField("BAS Setup Name");
                        BASSetup.FilterGroup(2);
                        BASSetup.SetRange("Setup Name", "BAS Setup Name");
                        BASSetup.FilterGroup(0);
                        BASSetupForm.SetTableView(BASSetup);
                        BASSetupForm.SetValues(A1, "BAS Version");
                        BASSetupForm.RunModal;
                    end;
                }
                action(Comment)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Comment';
                    Image = ViewComments;
                    RunObject = Page "BAS Comment Lines";
                    RunPageLink = "No." = FIELD(A1),
                                  "Version No." = FIELD("BAS Version");
                    ToolTip = 'Specifies an optional comment for this entry.';
                }
            }
        }
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
                action("E&xport")
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
                separator(Action214)
                {
                    Caption = '';
                }
                action("Calculate GST Settlement")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculate GST Settlement';
                    Image = CalculateSalesTax;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Start the process of calculating the GST settlement.';

                    trigger OnAction()
                    begin
                        BASCalcSheet.Reset();
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

    trigger OnInit()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.TestField("Enable GST (Australia)", true);
    end;

    var
        BASCalcSheetEntry: Record "BAS Calc. Sheet Entry";
        BASCalcSheet: Record "BAS Calculation Sheet";
        BASMngmt: Codeunit "BAS Management";
        BASImportExport: Report "BAS - Import/Export";

    local procedure BASEntryDrillDown(FieldID: Text[30])
    begin
        BASCalcSheetEntry.Reset();
        if "Group Consolidated" then begin
            BASCalcSheetEntry.SetCurrentKey("Consol. BAS Doc. No.", "Consol. Version No.");
            BASCalcSheetEntry.SetRange("Consol. BAS Doc. No.", A1);
            BASCalcSheetEntry.SetRange("Consol. Version No.", "BAS Version");
        end else begin
            BASCalcSheetEntry.SetRange("Company Name", CompanyName);
            BASCalcSheetEntry.SetRange("BAS Document No.", A1);
            BASCalcSheetEntry.SetRange("BAS Version", "BAS Version");
        end;
        BASCalcSheetEntry.SetRange("Field Label No.", FieldID);
        PAGE.RunModal(PAGE::"BAS Calc. Sheet Entries", BASCalcSheetEntry);
    end;
}

