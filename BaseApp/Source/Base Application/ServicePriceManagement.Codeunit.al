codeunit 6080 "Service Price Management"
{

    trigger OnRun()
    begin
    end;

    var
        ServHeader: Record "Service Header";
        Currency: Record Currency;
        TotalAmount: Decimal;

        Text001: Label 'There are no Service Lines to adjust.';
        Text002: Label 'Perform price adjustment?';
        Text003: Label 'This will remove all discounts on the Service Lines. Continue?';
        Text004: Label 'No Service Lines were found for %1 no. %2.';
        Text008: Label 'Perform price adjustment?';

    procedure ShowPriceAdjustment(ServItemLine: Record "Service Item Line")
    var
        ServPriceGrSetup: Record "Serv. Price Group Setup";
        ServLinePriceAdjmt: Record "Service Line Price Adjmt.";
        ServLine: Record "Service Line";
        ConfirmManagement: Codeunit "Confirm Management";
        ServPriceAdjmtForm: Page "Service Line Price Adjmt.";
    begin
        ServItemLine.TestField("Service Price Group Code");

        if ServItemLine."Serv. Price Adjmt. Gr. Code" = '' then
            Error(Text001);

        ServLinePriceAdjmt."Document Type" := ServItemLine."Document Type";
        ServLinePriceAdjmt."Document No." := ServItemLine."Document No.";
        GetServHeader(ServLinePriceAdjmt);
        GetServPriceGrSetup(ServPriceGrSetup, ServHeader, ServItemLine);
        with ServLinePriceAdjmt do begin
            Reset();
            SetRange("Document Type", ServItemLine."Document Type");
            SetRange("Document No.", ServItemLine."Document No.");
            SetRange("Service Item Line No.", ServItemLine."Line No.");
            if FindFirst() then
                DeleteAll();
            ServLine.Reset();
            ServLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.");
            ServLine.SetRange("Document Type", ServItemLine."Document Type");
            ServLine.SetRange("Document No.", ServItemLine."Document No.");
            ServLine.SetRange("Service Item Line No.", ServItemLine."Line No.");
            if not ServLine.Find('-') then
                Error(Text004, ServItemLine.TableCaption(), ServItemLine."Line No.");

            if not ServPriceGrSetup."Include Discounts" then
                if not ConfirmManagement.GetResponseOrDefault(Text003, true) then
                    exit;
            repeat
                if LineWithinFilter(ServLine, ServItemLine."Serv. Price Adjmt. Gr. Code") and
                   (ServItemLine."Serv. Price Adjmt. Gr. Code" <> '')
                then begin
                    "Vat %" := ServLine."VAT %";
                    if ServHeader."Prices Including VAT" then
                        ServLine."VAT %" := 0;
                    if not ServPriceGrSetup."Include Discounts" then begin
                        ServLine.TestField(Warranty, false);
                        ServLine.Validate("Line Discount %", 0);
                    end;
                    "Document Type" := ServLine."Document Type";
                    "Document No." := ServLine."Document No.";
                    "Service Line No." := ServLine."Line No.";
                    "Service Item Line No." := ServLine."Service Item Line No.";
                    "Service Item No." := ServLine."Service Item No.";
                    "Serv. Price Adjmt. Gr. Code" := ServItemLine."Serv. Price Adjmt. Gr. Code";
                    Type := ServLine.Type;
                    "No." := ServLine."No.";
                    Description := ServLine.Description;
                    Quantity := ServLine.Quantity - ServLine."Quantity Consumed" - ServLine."Qty. to Consume";

                    Amount := ServLine."Line Amount";
                    "New Amount" := ServLine."Line Amount";
                    "Unit Price" := ServLine."Unit Price";
                    "New Unit Price" := ServLine."Unit Price";
                    "Unit Cost" := ServLine."Unit Cost";
                    "Discount %" := ServLine."Line Discount %";
                    "Discount Amount" := ServLine."Line Discount Amount";
                    "Amount incl. VAT" := ServLine."Amount Including VAT";
                    "New Amount incl. VAT" := ServLine."Amount Including VAT";
                    "New Amount Excl. VAT" :=
                      Round(
                        ServLine."Amount Including VAT" / (1 + "Vat %" / 100),
                        Currency."Amount Rounding Precision");
                    "Adjustment Type" := ServPriceGrSetup."Adjustment Type";
                    "Service Price Group Code" := ServItemLine."Service Price Group Code";
                    Insert();
                end;
            until ServLine.Next() = 0;
            CalculateWeight(ServLinePriceAdjmt, ServPriceGrSetup);
        end;

        if ServLinePriceAdjmt.FindFirst() then begin
            Commit();
            Clear(ServPriceAdjmtForm);
            ServPriceAdjmtForm.SetVars(ServPriceGrSetup.Amount, ServPriceGrSetup."Include VAT");
            ServPriceAdjmtForm.SetTableView(ServLinePriceAdjmt);
            if ServPriceAdjmtForm.RunModal() = ACTION::OK then
                if ConfirmManagement.GetResponseOrDefault(Text002, true) then
                    PerformAdjustment(ServLinePriceAdjmt, ServPriceGrSetup."Include VAT");
            with ServLinePriceAdjmt do begin
                Reset();
                SetRange("Document Type", ServItemLine."Document Type");
                SetRange("Document No.", ServItemLine."Document No.");
                SetRange("Service Item Line No.", ServItemLine."Line No.");
                if FindFirst() then
                    DeleteAll();
            end;
        end else
            Error(Text001);
    end;

    procedure AdjustLines(ServLinePriceAdjmt: Record "Service Line Price Adjmt."; ServPriceGrSetup: Record "Serv. Price Group Setup")
    var
        ConfirmManagement: Codeunit "Confirm Management";
        TotalAmount: Decimal;
    begin
        if not ConfirmManagement.GetResponseOrDefault(Text008, true) then
            exit;
        with ServLinePriceAdjmt do
            if ServPriceGrSetup."Adjustment Type" = ServPriceGrSetup."Adjustment Type"::Fixed then
                AdjustFixed(ServLinePriceAdjmt, ServPriceGrSetup.Amount, ServPriceGrSetup."Include VAT")
            else begin
                Reset();
                SetRange("Document Type", "Document Type");
                SetRange("Document No.", "Document No.");
                SetRange("Service Item Line No.", "Service Item Line No.");
                CalcSums(Amount, "Amount incl. VAT");
                TotalAmount := Amount;
                if ServPriceGrSetup."Include VAT" then
                    TotalAmount := "Amount incl. VAT";
                if ServPriceGrSetup."Adjustment Type" = ServPriceGrSetup."Adjustment Type"::Maximum then begin
                    if TotalAmount > ServPriceGrSetup.Amount then
                        AdjustFixed(ServLinePriceAdjmt, ServPriceGrSetup.Amount, ServPriceGrSetup."Include VAT");
                end else
                    if TotalAmount < ServPriceGrSetup.Amount then
                        AdjustFixed(ServLinePriceAdjmt, ServPriceGrSetup.Amount, ServPriceGrSetup."Include VAT");
            end;
    end;

    local procedure AdjustFixed(ServLinePriceAdjmt: Record "Service Line Price Adjmt."; FixedPrice: Decimal; InclVat: Boolean)
    begin
        GetServHeader(ServLinePriceAdjmt);
        with ServLinePriceAdjmt do begin
            Reset();
            SetRange("Document Type", "Document Type");
            SetRange("Document No.", "Document No.");
            if Find('-') then
                repeat
                    if ServHeader."Prices Including VAT" and not InclVat then
                        FixedPrice := Round(FixedPrice + FixedPrice * "Vat %" / 100, 0.00001);
                    if InclVat then
                        Validate("New Amount incl. VAT", Round(FixedPrice * Weight / 100, Currency."Amount Rounding Precision"))
                    else
                        Validate("New Amount", Round(FixedPrice * Weight / 100, Currency."Amount Rounding Precision"));
                    Modify();
                until Next() = 0;
        end;
    end;

    local procedure CalculateWeight(ServLinePriceAdjmt: Record "Service Line Price Adjmt."; ServPriceGrSetup: Record "Serv. Price Group Setup")
    begin
        with ServLinePriceAdjmt do begin
            Reset();
            SetRange("Document Type", "Document Type");
            SetRange("Document No.", "Document No.");
            SetRange("Service Item Line No.", "Service Item Line No.");
            CalcSums(Amount, "Amount incl. VAT");
            if ServPriceGrSetup."Include VAT" then
                TotalAmount := "Amount incl. VAT"
            else
                TotalAmount := Amount;
            if not Find('-') then
                exit;
            repeat
                if ServPriceGrSetup."Include VAT" then begin
                    if TotalAmount <> 0 then
                        Weight := Round("Amount incl. VAT" * 100 / TotalAmount, 0.00001);
                end else
                    if TotalAmount <> 0 then
                        Weight := Round(Amount * 100 / TotalAmount, 0.00001);
                Modify();
            until Next() = 0;
        end;
    end;

    procedure GetServPriceGrSetup(var ServPriceGrSetup: Record "Serv. Price Group Setup"; ServHeader: Record "Service Header"; ServItemLine: Record "Service Item Line")
    begin
        with ServPriceGrSetup do begin
            Reset();
            SetRange("Service Price Group Code", ServItemLine."Service Price Group Code");
            SetFilter("Fault Area Code", '%1|%2', ServItemLine."Fault Area Code", '');
            SetFilter("Cust. Price Group Code", '%1|%2', ServHeader."Customer Price Group", '');
            SetRange("Currency Code", ServHeader."Currency Code");
            SetRange("Starting Date", 0D, ServHeader."Posting Date");
            if not Find('+') then
                Clear(ServPriceGrSetup);
        end;
    end;

    local procedure LineWithinFilter(ServLine: Record "Service Line"; ServPriceAdjmtGrCode: Code[10]): Boolean
    var
        Resource: Record Resource;
        ServPriceAdjmtDetail: Record "Serv. Price Adjustment Detail";
    begin
        if ServLine.Type = ServLine.Type::" " then
            exit(false);
        if ServLine.Warranty then
            exit(false);

        with ServPriceAdjmtDetail do begin
            Reset();
            SetRange("Serv. Price Adjmt. Gr. Code", ServPriceAdjmtGrCode);
            if IsEmpty() then
                exit(true);
            case ServLine.Type of
                ServLine.Type::Item:
                    SetRange(Type, Type::Item);
                ServLine.Type::Resource:
                    SetRange(Type, Type::Resource);
                ServLine.Type::Cost:
                    SetRange(Type, Type::"Service Cost");
                ServLine.Type::"G/L Account":
                    SetRange(Type, Type::"G/L Account");
                else
                    exit(false);
            end;
            SetFilter("No.", '%1|%2', ServLine."No.", '');
            SetFilter("Work Type", '%1|%2', ServLine."Work Type Code", '');
            SetFilter("Gen. Prod. Posting Group", '%1|%2', ServLine."Gen. Prod. Posting Group", '');
            if not IsEmpty() then
                exit(true);
            if ServLine.Type = ServLine.Type::Resource then begin
                Resource.Get(ServLine."No.");
                SetRange(Type, Type::"Resource Group");
                SetFilter("No.", '%1|%2', Resource."Resource Group No.", '');
                exit(not IsEmpty);
            end;
        end;
    end;

    local procedure PerformAdjustment(ServLinePriceAdjmt: Record "Service Line Price Adjmt."; InclVat: Boolean)
    var
        ServHeader: Record "Service Header";
        ServLine: Record "Service Line";
        OldVatPct: Decimal;
    begin
        with ServLinePriceAdjmt do begin
            ServHeader.Get("Document Type", "Document No.");
            Reset();
            SetRange("Document Type", "Document Type");
            SetRange("Document No.", "Document No.");
            SetRange("Service Item Line No.", "Service Item Line No.");
            if Find('-') then
                repeat
                    ServLine.Get("Document Type", "Document No.", "Service Line No.");
                    if ServHeader."Prices Including VAT" then begin
                        OldVatPct := ServLine."VAT %";
                        ServLine."VAT %" := 0;
                    end;
                    ServLine.Validate("Unit Price", "New Unit Price");
                    if "Discount %" = 0 then
                        ServLine.Validate("Line Discount %", 0);
                    if "New Amount incl. VAT" <> 0 then begin
                        if InclVat then
                            ServLine.Validate("Amount Including VAT", "New Amount incl. VAT")
                        else
                            ServLine.Validate("Line Amount", "New Amount");
                    end else
                        ServLine.Validate("Unit Price", 0);
                    if "Manually Adjusted" then
                        ServLine."Price Adjmt. Status" := ServLine."Price Adjmt. Status"::Modified
                    else
                        ServLine."Price Adjmt. Status" := ServLine."Price Adjmt. Status"::Adjusted;
                    if ServHeader."Prices Including VAT" then begin
                        ServLine."VAT %" := OldVatPct;
                        OldVatPct := 0;
                    end;
                    ServLine.Modify();
                until Next() = 0;
        end;
    end;

    procedure ResetAdjustedLines(ServLine: Record "Service Line")
    begin
        with ServLine do begin
            Reset();
            SetRange("Document Type", "Document Type");
            SetRange("Document No.", "Document No.");
            SetRange("Service Item Line No.", "Service Item Line No.");
            SetRange("Price Adjmt. Status", "Price Adjmt. Status"::Adjusted);
            if Find('-') then
                repeat
                    SetHideReplacementDialog(true);
                    UpdateUnitPrice(FieldNo("Unit Price"));
                    "Price Adjmt. Status" := "Price Adjmt. Status"::" ";
                    Modify();
                until Next() = 0;
        end;
    end;

    procedure CheckServItemGrCode(var ServLine: Record "Service Line")
    var
        ServItemLine: Record "Service Item Line";
    begin
        with ServLine do begin
            if ServItemLine.Get(ServItemLine."Document Type"::Order, "Document No.", "Service Item Line No.") then
                ServItemLine.TestField("Service Price Group Code");

            if ServItemLine."Serv. Price Adjmt. Gr. Code" = '' then
                Error(Text001);
        end;
    end;

    local procedure GetServHeader(ServLinePriceAdjmt: Record "Service Line Price Adjmt.")
    begin
        ServHeader.Get(ServLinePriceAdjmt."Document Type", ServLinePriceAdjmt."Document No.");
        if ServHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else begin
            ServHeader.TestField("Currency Factor");
            Currency.Get(ServHeader."Currency Code");
            Currency.TestField("Amount Rounding Precision");
        end;
    end;

    procedure IsLineToAdjustFirstInvoiced(var ServLine: Record "Service Line"): Boolean
    var
        ServLine2: Record "Service Line";
    begin
        ServLine2 := ServLine;
        with ServLine2 do begin
            ServLine.Reset();
            ServLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.");
            ServLine.SetRange("Document Type", "Document Type");
            ServLine.SetRange("Document No.", "Document No.");
            ServLine.SetRange("Service Item Line No.", "Service Item Line No.");
            ServLine.SetRange("Price Adjmt. Status", ServLine."Price Adjmt. Status"::" ");
            ServLine.SetRange("Quantity Invoiced", 0);
            if ServLine.Find('-') then begin
                ServLine := ServLine2;
                exit(true);
            end;
        end;
        ServLine := ServLine2;
        exit(false);
    end;
}

