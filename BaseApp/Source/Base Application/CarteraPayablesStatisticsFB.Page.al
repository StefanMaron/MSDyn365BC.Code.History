page 35305 "Cartera Payables Statistics FB"
{
    Caption = 'Cartera Payables Statistics FB';
    Editable = false;
    PageType = CardPart;
    SourceTable = Vendor;

    layout
    {
        area(content)
        {
            group("No. of Documents")
            {
                Caption = 'No. of Documents';
                field("NoOpen[1]"; NoOpen[1])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open Documents';
                    Editable = false;
                    ToolTip = 'Specifies non-processed payments.';
                }
                field("NoOpen[2]"; NoOpen[2])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open Docs. in Payment Order';
                    Editable = false;
                    ToolTip = 'Specifies non-processed payments.';
                }
                field("NoOpen[3]"; NoOpen[3])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open Docs. in Posted Payment Order';
                    Editable = false;
                    ToolTip = 'Specifies non-processed payments.';
                }
                field("NoHonored[3]"; NoHonored[3])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Honored Docs. in Posted Payment Order';
                    Editable = false;
                    ToolTip = 'Specifies settled payments.';
                }
            }
            group("Remaining Amt.  (LCY)")
            {
                Caption = 'Remaining Amt.  (LCY)';
                field("OpenRemainingAmtLCY[1]"; OpenRemainingAmtLCY[1])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Open Documents';
                    Editable = false;
                    ToolTip = 'Specifies non-processed payments.';

                    trigger OnDrillDown()
                    begin
                        DrillDownOpen(4); // Cartera
                    end;
                }
                field("OpenRemainingAmtLCY[2]"; OpenRemainingAmtLCY[2])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Open Docs. in Payment Order';
                    Editable = false;
                    ToolTip = 'Specifies non-processed payments.';

                    trigger OnDrillDown()
                    begin
                        DrillDownOpen(3); // Payment Order
                    end;
                }
                field("OpenRemainingAmtLCY[3]"; OpenRemainingAmtLCY[3])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Open Docs. in Posted Payment Order';
                    Editable = false;
                    ToolTip = 'Specifies non-processed payments.';

                    trigger OnDrillDown()
                    begin
                        DrillDownOpen(1); // Posted Payment Order
                    end;
                }
                field("HonoredRemainingAmtLCY[3]"; HonoredRemainingAmtLCY[3])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Honored Docs. in Posted Payment Order';
                    Editable = false;
                    ToolTip = 'Specifies settled payments.';

                    trigger OnDrillDown()
                    begin
                        DrillDownHonored(1); // Posted Payment Order
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        UpdateBillStatistics;
    end;

    var
        j: Integer;
        NoOpen: array[3] of Integer;
        NoHonored: array[3] of Integer;
        OpenAmtLCY: array[3] of Decimal;
        OpenRemainingAmtLCY: array[3] of Decimal;
        HonoredAmtLCY: array[3] of Decimal;
        HonoredRemainingAmtLCY: array[3] of Decimal;
        DocumentSituationFilter: array[3] of Option " ","Posted BG/PO","Closed BG/PO","BG/PO",Cartera,"Closed Documents";

    [Scope('OnPrem')]
    procedure UpdateBillStatistics()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        DocumentSituationFilter[1] := DocumentSituationFilter::Cartera;
        DocumentSituationFilter[2] := DocumentSituationFilter::"BG/PO";
        DocumentSituationFilter[3] := DocumentSituationFilter::"Posted BG/PO";

        with VendLedgEntry do begin
            SetCurrentKey("Vendor No.", "Document Type", "Document Situation", "Document Status");
            SetRange("Vendor No.", Rec."No.");
            for j := 1 to 3 do begin
                SetRange("Document Situation", DocumentSituationFilter[j]);
                SetRange("Document Status", "Document Status"::Open);
                CalcSums("Amount (LCY) stats.", "Remaining Amount (LCY) stats.");
                OpenAmtLCY[j] := "Amount (LCY) stats.";
                OpenRemainingAmtLCY[j] := "Remaining Amount (LCY) stats.";
                NoOpen[j] := Count;
                SetRange("Document Status");

                SetRange("Document Status", "Document Status"::Honored);
                CalcSums("Amount (LCY) stats.", "Remaining Amount (LCY) stats.");
                HonoredAmtLCY[j] := "Amount (LCY) stats.";
                HonoredRemainingAmtLCY[j] := "Remaining Amount (LCY) stats.";
                NoHonored[j] := Count;
                SetRange("Document Status");

                SetRange("Document Situation");
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure DrillDownOpen(Situation: Option " ","Posted BG/PO","Closed BG/PO","BG/PO",Cartera,"Closed Documents")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntriesForm: Page "Vendor Ledger Entries";
    begin
        with VendLedgEntry do begin
            SetCurrentKey("Vendor No.", "Document Type", "Document Situation", "Document Status");
            SetRange("Vendor No.", Rec."No.");
            case Situation of
                Situation::Cartera:
                    SetRange("Document Situation", "Document Situation"::Cartera);
                Situation::"BG/PO":
                    SetRange("Document Situation", "Document Situation"::"BG/PO");
                Situation::"Posted BG/PO":
                    SetRange("Document Situation", "Document Situation"::"Posted BG/PO");
            end;
            SetRange("Document Status", "Document Status"::Open);
            VendLedgEntriesForm.SetTableView(VendLedgEntry);
            VendLedgEntriesForm.SetRecord(VendLedgEntry);
            VendLedgEntriesForm.RunModal();
            SetRange("Document Status");
            SetRange("Document Situation");
        end;
    end;

    [Scope('OnPrem')]
    procedure DrillDownHonored(Situation: Option " ","Posted BG/PO","Closed BG/PO","BG/PO",Cartera,"Closed Documents")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntriesForm: Page "Vendor Ledger Entries";
    begin
        with VendLedgEntry do begin
            SetCurrentKey("Vendor No.", "Document Type", "Document Situation", "Document Status");
            SetRange("Vendor No.", Rec."No.");
            case Situation of
                Situation::Cartera:
                    SetRange("Document Situation", "Document Situation"::Cartera);
                Situation::"BG/PO":
                    SetRange("Document Situation", "Document Situation"::"BG/PO");
                Situation::"Posted BG/PO":
                    SetRange("Document Situation", "Document Situation"::"Posted BG/PO");
            end;

            SetRange("Document Status", "Document Status"::Honored);
            VendLedgEntriesForm.SetTableView(VendLedgEntry);
            VendLedgEntriesForm.SetRecord(VendLedgEntry);
            VendLedgEntriesForm.RunModal();
            SetRange("Document Status");
            SetRange("Document Situation");
        end;
    end;
}

