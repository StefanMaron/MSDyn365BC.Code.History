﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Sales.Receivables;

page 35294 "Closed BG Analysis LCY FB"
{
    Caption = 'Closed BG Analysis LCY FB';
    DataCaptionExpression = Caption();
    Editable = false;
    PageType = CardPart;
    SourceTable = "Closed Bill Group";

    layout
    {
        area(content)
        {
            field("Currency Code"; Rec."Currency Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the currency code the bill group was generated in.';
            }
            field("Amount Grouped"; Rec."Amount Grouped")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the grouped amount in this closed bill group.';
            }
            group("No. of documents")
            {
                Caption = 'No. of documents';
                field(NoHonored; NoHonored)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Honored';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is settled. ';
                }
                field(NoRejected; NoRejected)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Rejected';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is rejected.';
                }
                field(NoRedrawn; NoRedrawn)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Redrawn';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is recirculated because it was rejected when its due date arrived.';
                }
            }
            group("Amount (LCY)")
            {
                Caption = 'Amount (LCY)';
                field(Honored; HonoredAmtLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Honored';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is settled. ';
                }
                field(Rejected; RejectedAmtLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Rejected';
                    Editable = false;
                    ToolTip = 'Specifies that the related payment is rejected.';
                }
                field(Redrawn; RedrawnAmtLCY)
                {
                    ApplicationArea = Basic, Suite;
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
            SetRange(Type, Type::Receivable);
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

