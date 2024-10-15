page 742 "VAT Report Statement Subform"
{
    Caption = 'BAS Report Statement Lines';
    InsertAllowed = false;
    PageType = ListPart;
    ShowFilter = false;
    SourceTable = "VAT Statement Report Line";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Row No."; "Row No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a number that identifies the line.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the VAT report statement.';
                }
                field("Box No."; "Box No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number on the box that the VAT statement applies to.';
                }
                field(Base; Base)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that the VAT amount in the amount is calculated from.';
                    Visible = ShowBase;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = true;
                    ToolTip = 'Specifies the amount of the entry in the report statement.';

                    trigger OnDrillDown()
                    var
                        BASManagement: Codeunit "BAS Management";
                    begin
                        if BASManagement.VATStatementRepLineChangesAllowed(Rec) then
                            BASEntryDrillDown;
                    end;

                    trigger OnValidate()
                    var
                        VATStatementLine: Record "VAT Statement Line";
                        VATReportHeader: Record "VAT Report Header";
                    begin
                        VATReportHeader.Get("VAT Report Config. Code", "VAT Report No.");
                        VATStatementLine.SetRange("Statement Template Name", VATReportHeader."Statement Template Name");
                        VATStatementLine.SetRange("Statement Name", VATReportHeader."Statement Name");
                        VATStatementLine.SetRange("Box No.", "Box No.");
                        VATStatementLine.FindFirst;
                        VATStatementLine.TestField(Type, VATStatementLine.Type::Description);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    var
        ShowBase: Boolean;

    trigger OnOpenPage()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        ShowBase := VATReportSetup."Report VAT Base";
    end;

    procedure SelectFirst()
    begin
        if Count > 0 then
            FindFirst;
    end;

    local procedure BASEntryDrillDown()
    var
        VATEntry: Record "VAT Entry";
        TempVATEntry: Record "VAT Entry" temporary;
        VATStatementLine1: Record "VAT Statement Line";
        VATStatementLine2: Record "VAT Statement Line";
        VATReportHeader: Record "VAT Report Header";
        GLEntry: Record "G/L Entry";
    begin
        VATReportHeader.Get("VAT Report Config. Code", "VAT Report No.");
        VATStatementLine1.SetRange("Statement Template Name", VATReportHeader."Statement Template Name");
        VATStatementLine1.SetRange("Statement Name", VATReportHeader."Statement Name");
        VATStatementLine1.SetRange("Box No.", "Box No.");
        VATStatementLine1.SetRange("Row No.", "Row No.");
        VATStatementLine1.FindFirst;
        case VATStatementLine1.Type of
            VATStatementLine1.Type::"Row Totaling":
                begin
                    VATStatementLine2.SetRange("Statement Template Name", VATReportHeader."Statement Template Name");
                    VATStatementLine2.SetRange("Statement Name", VATReportHeader."Statement Name");
                    VATStatementLine2.SetRange("Row No.", VATStatementLine1."Row Totaling");
                    if VATStatementLine2.FindSet then
                        repeat
                            VATEntry.Reset();
                            VATEntry.SetRange(Type, VATStatementLine2."Gen. Posting Type");
                            VATEntry.SetRange("VAT Bus. Posting Group", VATStatementLine2."VAT Bus. Posting Group");
                            VATEntry.SetRange("VAT Prod. Posting Group", VATStatementLine2."VAT Prod. Posting Group");
                            VATEntry.SetRange("Tax Jurisdiction Code", VATStatementLine2."Tax Jurisdiction Code");
                            VATEntry.SetRange("Use Tax", VATStatementLine2."Use Tax");
                            VATEntry.SetRange("BAS Adjustment", VATStatementLine2."BAS Adjustment");
                            if VATReportHeader."Include Prev. Open Entries" then
                                VATEntry.SetRange("Posting Date", 0D, VATReportHeader."End Date")
                            else
                                VATEntry.SetRange("Posting Date", VATReportHeader."Start Date", VATReportHeader."End Date");
                            VATEntry.SetRange(Closed, false);
                            if VATEntry.FindSet then
                                repeat
                                    if not TempVATEntry.Get(VATEntry."Entry No.") then begin
                                        TempVATEntry.Copy(VATEntry);
                                        TempVATEntry.Insert();
                                    end;
                                until VATEntry.Next() = 0;
                        until VATStatementLine2.Next() = 0;
                    TempVATEntry.Reset();
                    PAGE.Run(PAGE::"VAT Entries", TempVATEntry);
                end;
            VATStatementLine1.Type::"Account Totaling":
                begin
                    GLEntry.SetFilter("G/L Account No.", VATStatementLine1."Account Totaling");
                    GLEntry.SetFilter("Posting Date", '%1..%2', VATReportHeader."Start Date", VATReportHeader."End Date");
                    PAGE.Run(PAGE::"General Ledger Entries", GLEntry);
                end;
        end;
    end;
}

