// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Sales.Customer;

page 35304 "Cartera Receiv. Statistics FB"
{
    Caption = 'Cartera Receiv. Statistics FB';
    Editable = false;
    PageType = CardPart;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            group("No. of Bills")
            {
                Caption = 'No. of Bills';
                field("NoOpen[1]"; NoOpen[1])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open Bills';
                    Editable = false;
                    ToolTip = 'Specifies non-processed payments.';
                }
                field("NoOpen[2]"; NoOpen[2])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open Bills in Bill Gr.';
                    Editable = false;
                    ToolTip = 'Specifies non-processed payments.';
                }
                field("NoOpen[3]"; NoOpen[3])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open Bills in Post. Bill Gr.';
                    Editable = false;
                    ToolTip = 'Specifies non-processed payments.';
                }
                field("NoHonored[3]"; NoHonored[3])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Hon. Bills in Post. Bill Gr.';
                    Editable = false;
                    ToolTip = 'Specifies settled payments.';
                }
                field("NoRejected[3]"; NoRejected[3])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Rej. Bills in Post. Bill Gr.';
                    Editable = false;
                    ToolTip = 'Specifies rejected payments.';
                }
                field("NoRedrawn[3]"; NoRedrawn[3])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Redr. Bills in Post. Bill Gr.';
                    Editable = false;
                    ToolTip = 'Specifies recirculated payments.';
                }
                field("NoHonored[4]"; NoHonored[4])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Hon. Closed Bills';
                    Editable = false;
                    ToolTip = 'Specifies settled payments.';
                }
                field("NoRejected[4]"; NoRejected[4])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Rej. Closed Bills';
                    Editable = false;
                    ToolTip = 'Specifies rejected payments.';
                }
            }
            group("Remaining Amt.  (LCY)")
            {
                Caption = 'Remaining Amt.  (LCY)';
                field("OpenRemainingAmtLCY[1]"; OpenRemainingAmtLCY[1])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Open Bills';
                    Editable = false;
                    ToolTip = 'Specifies non-processed payments.';

                    trigger OnDrillDown()
                    begin
                        DrillDownOpen(4, 1); // Cartera
                    end;
                }
                field("OpenRemainingAmtLCY[2]"; OpenRemainingAmtLCY[2])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Open Bills in Bill Gr.';
                    Editable = false;
                    ToolTip = 'Specifies non-processed payments.';

                    trigger OnDrillDown()
                    begin
                        DrillDownOpen(3, 1); // Bill Group;
                    end;
                }
                field("OpenRemainingAmtLCY[3]"; OpenRemainingAmtLCY[3])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Open Bills in Post. Bill Gr.';
                    Editable = false;
                    ToolTip = 'Specifies non-processed payments.';

                    trigger OnDrillDown()
                    begin
                        DrillDownOpen(1, 1); // Posted Bill Group
                    end;
                }
                field("HonoredRemainingAmtLCY[3]"; HonoredRemainingAmtLCY[3])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Hon. Bills in Post. Bill Gr.';
                    Editable = false;
                    ToolTip = 'Specifies settled payments.';

                    trigger OnDrillDown()
                    begin
                        DrillDownHonored(1, 1); // Posted Bill Group
                    end;
                }
                field("RejectedRemainingAmtLCY[3]"; RejectedRemainingAmtLCY[3])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Rej. Bills in Post. Bill Gr.';
                    Editable = false;
                    ToolTip = 'Specifies rejected payments.';

                    trigger OnDrillDown()
                    begin
                        DrillDownRejected(1, 1); // Posted Bill Group
                    end;
                }
                field("RedrawnRemainingAmtLCY[3]"; RedrawnRemainingAmtLCY[3])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Redr. Bills in Post. Bill Gr.';
                    Editable = false;
                    ToolTip = 'Specifies recirculated payments.';

                    trigger OnDrillDown()
                    begin
                        DrillDownRedrawn(1, 1); // Posted Bill Group
                    end;
                }
                field("HonoredRemainingAmtLCY[4]"; HonoredRemainingAmtLCY[4])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Hon. Closed Bills';
                    Editable = false;
                    ToolTip = 'Specifies settled payments.';

                    trigger OnDrillDown()
                    begin
                        DrillDownHonored(5, 1); // Closed Bills
                    end;
                }
                field("RejectedRemainingAmtLCY[4]"; RejectedRemainingAmtLCY[4])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Rej. Closed Bills';
                    Editable = false;
                    ToolTip = 'Specifies rejected payments.';

                    trigger OnDrillDown()
                    begin
                        DrillDownRejected(5, 1); // Closed Bills
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
        UpdateDocStatistics();
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

    [Scope('OnPrem')]
    procedure UpdateDocStatistics()
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

    [Scope('OnPrem')]
    procedure DrillDownOpen(Situation: Option " ","Posted BG/PO","Closed BG/PO","BG/PO",Cartera,"Closed Documents"; DocType: Option Invoice,Bill)
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

    [Scope('OnPrem')]
    procedure DrillDownHonored(Situation: Option " ","Posted BG/PO","Closed BG/PO","BG/PO",Cartera,"Closed Documents"; DocType: Option Invoice,Bill)
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

    [Scope('OnPrem')]
    procedure DrillDownRejected(Situation: Option " ","Posted BG/PO","Closed BG/PO","BG/PO",Cartera,"Closed Documents"; DocType: Option Invoice,Bill)
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

    [Scope('OnPrem')]
    procedure DrillDownRedrawn(Situation: Option " ","Posted BG/PO","Closed BG/PO","BG/PO",Cartera,"Closed Documents"; DocType: Option Invoice,Bill)
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
                Situation::"Closed BG/PO", Situation::"Closed Documents":
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
            SetRange("Document Status", "Document Status"::Redrawn);
            CustLedgEntriesForm.SetTableView(CustLedgEntry);
            CustLedgEntriesForm.SetRecord(CustLedgEntry);
            CustLedgEntriesForm.RunModal();
            SetRange("Document Status");
            SetRange("Document Situation");
        end;
    end;
}

