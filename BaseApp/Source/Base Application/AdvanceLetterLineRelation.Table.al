table 31026 "Advance Letter Line Relation"
{
    Caption = 'Advance Letter Line Relation';
    DrillDownPageID = "Advance Letter Line Relations";
    LookupPageID = "Advance Letter Line Relations";
    Permissions =;

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Sale,Purchase';
            OptionMembers = Sale,Purchase;
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = IF (Type = CONST(Sale)) "Sales Header"."No." WHERE("Document Type" = FIELD("Document Type"))
            ELSE
            IF (Type = CONST(Purchase)) "Purchase Header"."No." WHERE("Document Type" = FIELD("Document Type"));
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(3; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
            TableRelation = IF (Type = CONST(Sale)) "Sales Line"."Line No." WHERE("Document Type" = FIELD("Document Type"),
                                                                                 "Document No." = FIELD("Document No."))
            ELSE
            IF (Type = CONST(Purchase)) "Purchase Line"."Line No." WHERE("Document Type" = FIELD("Document Type"),
                                                                                                                                                  "Document No." = FIELD("Document No."));
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(4; "Letter No."; Code[20])
        {
            Caption = 'Letter No.';
            TableRelation = IF (Type = CONST(Sale)) "Sales Advance Letter Header"."No."
            ELSE
            IF (Type = CONST(Purchase)) "Purch. Advance Letter Header"."No.";
        }
        field(5; "Letter Line No."; Integer)
        {
            Caption = 'Letter Line No.';
            TableRelation = IF (Type = CONST(Sale)) "Sales Advance Letter Line"."Line No." WHERE("Letter No." = FIELD("Letter No."))
            ELSE
            IF (Type = CONST(Purchase)) "Purch. Advance Letter Line"."Line No." WHERE("Letter No." = FIELD("Letter No."));
        }
        field(6; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(7; "Requested Amount"; Decimal)
        {
            Caption = 'Requested Amount';
        }
        field(8; "Invoiced Amount"; Decimal)
        {
            Caption = 'Invoiced Amount';
        }
        field(9; "Deducted Amount"; Decimal)
        {
            Caption = 'Deducted Amount';
        }
        field(20; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Order,Invoice';
            OptionMembers = " ","Order",Invoice;
        }
        field(21; "Amount To Deduct"; Decimal)
        {
            Caption = 'Amount To Deduct';
        }
        field(22; "VAT Doc. VAT Base"; Decimal)
        {
            Caption = 'VAT Doc. VAT Base';
        }
        field(23; "VAT Doc. VAT Amount"; Decimal)
        {
            Caption = 'VAT Doc. VAT Amount';
        }
        field(24; "VAT Doc. VAT Base (LCY)"; Decimal)
        {
            Caption = 'VAT Doc. VAT Base (LCY)';
        }
        field(25; "VAT Doc. VAT Amount (LCY)"; Decimal)
        {
            Caption = 'VAT Doc. VAT Amount (LCY)';
        }
        field(26; "VAT Doc. VAT Difference"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Doc. VAT Difference';
            Editable = false;
        }
        field(27; "Primary Link"; Boolean)
        {
            Caption = 'Primary Link';
        }
    }

    keys
    {
        key(Key1; Type, "Document Type", "Document No.", "Document Line No.", "Letter No.", "Letter Line No.")
        {
            Clustered = true;
            SumIndexFields = Amount, "Invoiced Amount", "Deducted Amount", "Amount To Deduct";
        }
        key(Key2; Type, "Letter No.", "Letter Line No.", "Document No.", "Document Line No.")
        {
            SumIndexFields = Amount;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
    begin
        TestField("Deducted Amount", 0);
        CancelRelation(Rec, true, true, false);

        AdvanceLetterLineRelation.Reset;
        AdvanceLetterLineRelation.SetRange(Type, Type);
        AdvanceLetterLineRelation.SetRange("Document Type", "Document Type");
        AdvanceLetterLineRelation.SetRange("Document No.", "Document No.");
        AdvanceLetterLineRelation.SetRange("Document Line No.", "Document Line No.");
        if AdvanceLetterLineRelation.FindSet(true, false) then
            repeat
                if not ((AdvanceLetterLineRelation."Letter No." = "Letter No.") and (AdvanceLetterLineRelation."Letter Line No." = "Letter Line No."))
                then begin
                    AdvanceLetterLineRelation."VAT Doc. VAT Difference" := 0;
                    AdvanceLetterLineRelation.Modify;
                end;
            until AdvanceLetterLineRelation.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure CancelRelation(AdvanceLetterLineRelation: Record "Advance Letter Line Relation"; IsUpdateSalesPurchLine: Boolean; IsUpdateAdvPaymHeader: Boolean; IsDeleteRec: Boolean)
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        Currency: Record Currency;
        PurchLine: Record "Purchase Line";
        PurchHeader: Record "Purchase Header";
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        SalesPostAdvances: Codeunit "Sales-Post Advances";
        PurchPostAdvances: Codeunit "Purchase-Post Advances";
        IsDocLineFound: Boolean;
    begin
        case AdvanceLetterLineRelation.Type of
            AdvanceLetterLineRelation.Type::Sale:
                begin
                    SalesAdvanceLetterLine.Get(AdvanceLetterLineRelation."Letter No.", AdvanceLetterLineRelation."Letter Line No.");
                    if IsUpdateSalesPurchLine then begin
                        IsDocLineFound := SalesLine.Get(AdvanceLetterLineRelation."Document Type",
                            AdvanceLetterLineRelation."Document No.",
                            AdvanceLetterLineRelation."Document Line No.");
                        if IsDocLineFound then begin
                            SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
                            if SalesLine."Currency Code" = '' then
                                Currency.InitRoundingPrecision
                            else begin
                                Currency.Get(SalesLine."Currency Code");
                                Currency.TestField("Amount Rounding Precision");
                            end;
                            if SalesHeader."Prices Including VAT" then
                                SalesLine."Prepmt. Amt. Inv." := SalesLine."Prepmt. Amt. Inv." -
                                  AdvanceLetterLineRelation."Invoiced Amount" + AdvanceLetterLineRelation."Deducted Amount"
                            else
                                SalesLine."Prepmt. Amt. Inv." := SalesLine."Prepmt. Amt. Inv." -
                                  Round((AdvanceLetterLineRelation."Invoiced Amount" - AdvanceLetterLineRelation."Deducted Amount") /
                                    (1 + SalesLine."VAT %" / 100), Currency."Amount Rounding Precision");
                            SalesLine.CalcPrepaymentToDeduct;
                            SalesLine.Modify;
                        end;
                    end;

                    if IsUpdateAdvPaymHeader then begin
                        SalesAdvanceLetterHeader.Get("Letter No.");
                        if SalesAdvanceLetterHeader."Order No." <> '' then begin
                            SalesAdvanceLetterHeader."Order No." := '';
                            SalesAdvanceLetterHeader.Modify;
                        end;
                    end;
                end;
            AdvanceLetterLineRelation.Type::Purchase:
                begin
                    PurchAdvanceLetterLine.Get(AdvanceLetterLineRelation."Letter No.", AdvanceLetterLineRelation."Letter Line No.");
                    if IsUpdateSalesPurchLine then begin
                        IsDocLineFound := PurchLine.Get(AdvanceLetterLineRelation."Document Type",
                            AdvanceLetterLineRelation."Document No.",
                            AdvanceLetterLineRelation."Document Line No.");
                        if IsDocLineFound then begin
                            PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
                            if PurchLine."Currency Code" = '' then
                                Currency.InitRoundingPrecision
                            else begin
                                Currency.Get(PurchLine."Currency Code");
                                Currency.TestField("Amount Rounding Precision");
                            end;
                            if PurchHeader."Prices Including VAT" then
                                PurchLine."Prepmt. Amt. Inv." := PurchLine."Prepmt. Amt. Inv." -
                                  AdvanceLetterLineRelation."Invoiced Amount" + AdvanceLetterLineRelation."Deducted Amount"
                            else
                                PurchLine."Prepmt. Amt. Inv." := PurchLine."Prepmt. Amt. Inv." -
                                  Round((AdvanceLetterLineRelation."Invoiced Amount" - AdvanceLetterLineRelation."Deducted Amount") /
                                    (1 + PurchLine."VAT %" / 100), Currency."Amount Rounding Precision");
                            PurchLine.CalcPrepaymentToDeduct;
                            PurchLine.Modify;
                        end;
                    end;

                    if IsUpdateAdvPaymHeader then begin
                        PurchAdvanceLetterHeader.Get("Letter No.");
                        if PurchAdvanceLetterHeader."Order No." <> '' then begin
                            PurchAdvanceLetterHeader."Order No." := '';
                            PurchAdvanceLetterHeader.Modify;
                        end;
                    end;
                end;
        end;
        if AdvanceLetterLineRelation."Deducted Amount" = 0 then begin
            if IsDeleteRec then
                AdvanceLetterLineRelation.Delete
        end else begin
            AdvanceLetterLineRelation.Amount := AdvanceLetterLineRelation."Deducted Amount";
            AdvanceLetterLineRelation."Invoiced Amount" := AdvanceLetterLineRelation."Deducted Amount";
            AdvanceLetterLineRelation.Modify;
        end;
        case AdvanceLetterLineRelation.Type of
            AdvanceLetterLineRelation.Type::Sale:
                SalesPostAdvances.UpdInvAmountToLineRelations(SalesAdvanceLetterLine);
            AdvanceLetterLineRelation.Type::Purchase:
                PurchPostAdvances.UpdInvAmountToLineRelations(PurchAdvanceLetterLine);
        end;
    end;
}

