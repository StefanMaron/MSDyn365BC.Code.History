page 35306 "Cartera Fact. Statistics FB"
{
    Caption = 'Cartera Fact. Statistics FB';
    Editable = false;
    PageType = CardPart;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            group("No. of Invoices")
            {
                Caption = 'No. of Invoices';
                field("NoOpen[5]"; NoOpen[5])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is not processed yet. ';
                }
                field("NoHonored[5]"; NoHonored[5])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Honored';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is settled. ';
                }
                field("NoRejected[5]"; NoRejected[5])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Rejected';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is rejected.';
                }
            }
            group("Remaining Amt.  (LCY)")
            {
                Caption = 'Remaining Amt.  (LCY)';
                field("OpenRemainingAmtLCY[5]"; OpenRemainingAmtLCY[5])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Open';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is not processed yet. ';

                    trigger OnDrillDown()
                    begin
                        DrillDownOpen(0, 0);
                    end;
                }
                field("HonoredRemainingAmtLCY[5]"; HonoredRemainingAmtLCY[5])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Honored';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is settled. ';

                    trigger OnDrillDown()
                    begin
                        DrillDownHonored(0, 0);
                    end;
                }
                field("RejectedRemainingAmtLCY[5]"; RejectedRemainingAmtLCY[5])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Rejected';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is rejected.';

                    trigger OnDrillDown()
                    begin
                        DrillDownRejected(0, 0);
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
        UpdateDocStatistics;
    end;

    var
        DocumentSituationFilter: array[3] of Option " ","Posted BG/PO","Closed BG/PO","BG/PO",Cartera,"Closed Documents";
        NoOpen: array[5] of Integer;
        NoHonored: array[5] of Integer;
        NoRejected: array[5] of Integer;
        NoRedrawn: array[5] of Integer;
        OpenAmtLCY: array[5] of Decimal;
        HonoredAmtLCY: array[5] of Decimal;
        RejectedAmtLCY: array[5] of Decimal;
        RedrawnAmtLCY: array[5] of Decimal;
        OpenRemainingAmtLCY: array[5] of Decimal;
        RejectedRemainingAmtLCY: array[5] of Decimal;
        HonoredRemainingAmtLCY: array[5] of Decimal;
        RedrawnRemainingAmtLCY: array[5] of Decimal;
        j: Integer;

    local procedure UpdateDocStatistics()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        DocumentSituationFilter[1] := DocumentSituationFilter::Cartera;
        DocumentSituationFilter[2] := DocumentSituationFilter::"BG/PO";
        DocumentSituationFilter[3] := DocumentSituationFilter::"Posted BG/PO";

        with CustLedgEntry do begin
            SetCurrentKey("Customer No.", "Document Type", "Document Situation", "Document Status");
            SetRange("Customer No.", Rec."No.");
            for j := 1 to 5 do begin
                case j of
                    4: // Closed Bill Group and Closed Documents
                        begin
                            SetRange("Document Type", "Document Type"::Bill);
                            SetFilter("Document Situation", '%1|%2',
                              "Document Situation"::"Closed BG/PO",
                              "Document Situation"::"Closed Documents");
                        end;
                    5: // Invoices
                        begin
                            SetRange("Document Type", "Document Type"::Invoice);
                            SetFilter("Document Situation", '<>0');
                        end;
                    else begin
                            SetRange("Document Type", "Document Type"::Bill);
                            SetRange("Document Situation", DocumentSituationFilter[j]);
                        end;
                end;
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

                SetRange("Document Status", "Document Status"::Rejected);
                CalcSums("Amount (LCY) stats.", "Remaining Amount (LCY) stats.");
                RejectedAmtLCY[j] := "Amount (LCY) stats.";
                RejectedRemainingAmtLCY[j] := "Remaining Amount (LCY) stats.";
                NoRejected[j] := Count;
                SetRange("Document Status");

                SetRange("Document Status", "Document Status"::Redrawn);
                CalcSums("Amount (LCY) stats.", "Remaining Amount (LCY) stats.");
                RedrawnAmtLCY[j] := "Amount (LCY) stats.";
                RedrawnRemainingAmtLCY[j] := "Remaining Amount (LCY) stats.";
                NoRedrawn[j] := Count;
                SetRange("Document Status");

                SetRange("Document Situation");
            end;
        end;
    end;

    local procedure DrillDownOpen(Situation: Option " ","Posted BG/PO","Closed BG/PO","BG/PO",Cartera,"Closed Documents"; DocType: Option Invoice,Bill)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntriesForm: Page "Customer Ledger Entries";
    begin
        with CustLedgEntry do begin
            SetCurrentKey("Customer No.", "Document Type", "Document Situation", "Document Status");
            SetRange("Customer No.", Rec."No.");
            case Situation of
                Situation::Cartera:
                    SetRange("Document Situation", "Document Situation"::Cartera);
                Situation::"BG/PO":
                    SetRange("Document Situation", "Document Situation"::"BG/PO");
                Situation::"Posted BG/PO":
                    SetRange("Document Situation", "Document Situation"::"Posted BG/PO");
                Situation::"Closed BG/PO":
                    SetFilter("Document Situation", '%1|%2',
                      "Document Situation"::"Closed BG/PO",
                      "Document Situation"::"Closed Documents");
                else
                    SetFilter("Document Situation", '<>0');
            end;
            case DocType of
                DocType::Invoice:
                    SetRange("Document Type", "Document Type"::Invoice);
                DocType::Bill:
                    SetRange("Document Type", "Document Type"::Bill);
            end;

            SetRange("Document Status", "Document Status"::Open);
            CustLedgEntriesForm.SetTableView(CustLedgEntry);
            CustLedgEntriesForm.SetRecord(CustLedgEntry);
            CustLedgEntriesForm.RunModal();
            SetRange("Document Status");
            SetRange("Document Situation");
        end;
    end;

    local procedure DrillDownHonored(Situation: Option " ","Posted BG/PO","Closed BG/PO","BG/PO",Cartera,"Closed Documents"; DocType: Option Invoice,Bill)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntriesForm: Page "Customer Ledger Entries";
    begin
        with CustLedgEntry do begin
            SetCurrentKey("Customer No.", "Document Type", "Document Situation", "Document Status");
            SetRange("Customer No.", Rec."No.");
            case Situation of
                Situation::Cartera:
                    SetRange("Document Situation", "Document Situation"::Cartera);
                Situation::"BG/PO":
                    SetRange("Document Situation", "Document Situation"::"BG/PO");
                Situation::"Posted BG/PO":
                    SetRange("Document Situation", "Document Situation"::"Posted BG/PO");
                Situation::"Closed BG/PO":
                    SetFilter("Document Situation", '%1|%2',
                      "Document Situation"::"Closed BG/PO",
                      "Document Situation"::"Closed Documents");
                else
                    SetFilter("Document Situation", '<>0');
            end;
            case DocType of
                DocType::Invoice:
                    SetRange("Document Type", "Document Type"::Invoice);
                DocType::Bill:
                    SetRange("Document Type", "Document Type"::Bill);
            end;

            SetRange("Document Status", "Document Status"::Honored);
            CustLedgEntriesForm.SetTableView(CustLedgEntry);
            CustLedgEntriesForm.SetRecord(CustLedgEntry);
            CustLedgEntriesForm.RunModal();
            SetRange("Document Status");
            SetRange("Document Situation");
        end;
    end;

    local procedure DrillDownRejected(Situation: Option " ","Posted BG/PO","Closed BG/PO","BG/PO",Cartera,"Closed Documents"; DocType: Option Invoice,Bill)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntriesForm: Page "Customer Ledger Entries";
    begin
        with CustLedgEntry do begin
            SetCurrentKey("Customer No.", "Document Type", "Document Situation", "Document Status");
            SetRange("Customer No.", Rec."No.");
            case Situation of
                Situation::Cartera:
                    SetRange("Document Situation", "Document Situation"::Cartera);
                Situation::"BG/PO":
                    SetRange("Document Situation", "Document Situation"::"BG/PO");
                Situation::"Posted BG/PO":
                    SetRange("Document Situation", "Document Situation"::"Posted BG/PO");
                Situation::"Closed BG/PO":
                    SetFilter("Document Situation", '%1|%2',
                      "Document Situation"::"Closed BG/PO",
                      "Document Situation"::"Closed Documents");
                else
                    SetFilter("Document Situation", '<>0');
            end;
            case DocType of
                DocType::Invoice:
                    SetRange("Document Type", "Document Type"::Invoice);
                DocType::Bill:
                    SetRange("Document Type", "Document Type"::Bill);
            end;

            SetRange("Document Status", "Document Status"::Rejected);
            CustLedgEntriesForm.SetTableView(CustLedgEntry);
            CustLedgEntriesForm.SetRecord(CustLedgEntry);
            CustLedgEntriesForm.RunModal();
            SetRange("Document Status");
            SetRange("Document Situation");
        end;
    end;
}

