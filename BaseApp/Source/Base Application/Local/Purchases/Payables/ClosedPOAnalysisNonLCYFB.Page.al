// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.ReceivablesPayables;

page 35302 "Closed PO Analysis Non LCY FB"
{
    Caption = 'Closed PO Analysis Non LCY FB';
    DataCaptionExpression = Caption();
    Editable = false;
    PageType = CardPart;
    SourceTable = "Closed Payment Order";

    layout
    {
        area(content)
        {
            field("Currency Code"; Rec."Currency Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the currency code in which the payment order was generated.';
            }
            field("Amount Grouped"; Rec."Amount Grouped")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the grouped amount for this closed payment order.';
            }
            group("No. of Documents")
            {
                Caption = 'No. of Documents';
                field(NoHonored; NoHonored)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Honored';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is settled. ';
                }
                field(NoRedrawn; NoRedrawn)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Redrawn';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is recirculated because it was rejected when its due date arrived.';
                }
            }
            group(Amount)
            {
                Caption = 'Amount';
                field(Honored; HonoredAmt)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Honored';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is settled. ';
                }
                field(Rejected; RedrawnAmt)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Redrawn';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is recirculated because it was rejected when its due date arrived.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        UpdateStatistics();
    end;

    var
        ClosedDoc: Record "Closed Cartera Doc.";
        HonoredAmt: Decimal;
        RejectedAmt: Decimal;
        RedrawnAmt: Decimal;
        HonoredAmtLCY: Decimal;
        RejectedAmtLCY: Decimal;
        RedrawnAmtLCY: Decimal;
        NoHonored: Integer;
        NoRejected: Integer;
        NoRedrawn: Integer;

    local procedure UpdateStatistics()
    begin
        with ClosedDoc do begin
            SetCurrentKey(Type, "Collection Agent", "Bill Gr./Pmt. Order No.", "Currency Code", Status, Redrawn);
            SetRange(Type, Type::Payable);
            SetRange("Collection Agent", "Collection Agent"::Bank);
            SetRange("Bill Gr./Pmt. Order No.", Rec."No.");
            Rec.CopyFilter("Global Dimension 1 Filter", "Global Dimension 1 Code");
            Rec.CopyFilter("Global Dimension 2 Filter", "Global Dimension 2 Code");

            SetRange(Status, Status::Honored);
            SetRange(Redrawn, true);
            CalcSums("Amount for Collection", "Amt. for Collection (LCY)");
            RedrawnAmt := "Amount for Collection";
            RedrawnAmtLCY := "Amt. for Collection (LCY)";
            NoRedrawn := Count;

            SetRange(Redrawn, false);
            CalcSums("Amount for Collection", "Amt. for Collection (LCY)");
            HonoredAmt := "Amount for Collection";
            HonoredAmtLCY := "Amt. for Collection (LCY)";
            NoHonored := Count;
            SetRange(Redrawn);

            SetRange(Status, Status::Rejected);
            CalcSums("Amount for Collection", "Amt. for Collection (LCY)");
            RejectedAmt := "Amount for Collection";
            RejectedAmtLCY := "Amt. for Collection (LCY)";
            NoRejected := Count;
            SetRange(Status);
        end;
    end;
}

