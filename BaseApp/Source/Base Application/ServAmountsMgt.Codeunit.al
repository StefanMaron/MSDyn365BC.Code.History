codeunit 5986 "Serv-Amounts Mgt."
{
    Permissions = TableData "Invoice Post. Buffer" = imd,
                  TableData "General Posting Setup" = imd,
                  TableData "VAT Amount Line" = imd,
                  TableData "Dimension Buffer" = imd,
                  TableData "Service Line" = imd;

    trigger OnRun()
    begin
    end;

    var
        Currency: Record Currency;
        SalesSetup: Record "Sales & Receivables Setup";
        DimBufMgt: Codeunit "Dimension Buffer Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        FALineNo: Integer;
        RoundingLineNo: Integer;
        Text016: Label 'VAT Amount';
        Text017: Label '%1% VAT';
        RoundingLineIsInserted: Boolean;
        IsInitialized: Boolean;
        SuppressCommit: Boolean;

    procedure Initialize(CurrencyCode: Code[10])
    begin
        RoundingLineIsInserted := false;
        GetCurrency(CurrencyCode, Currency);
        SalesSetup.Get();
        IsInitialized := true;
    end;

    procedure GetDimensions(DimensionEntryNo: Integer; var TempDimBuf: Record "Dimension Buffer")
    begin
        DimBufMgt.GetDimensions(DimensionEntryNo, TempDimBuf);
    end;

    procedure Finalize()
    begin
        IsInitialized := false;
    end;

    procedure FillInvPostingBuffer(var InvPostingBuffer: array[2] of Record "Invoice Post. Buffer"; var ServiceLine: Record "Service Line"; var ServiceLineACY: Record "Service Line"; ServiceHeader: Record "Service Header")
    var
        GenPostingSetup: Record "General Posting Setup";
        ServCost: Record "Service Cost";
        TotalVAT: Decimal;
        TotalVATACY: Decimal;
        TotalAmount: Decimal;
        TotalAmountACY: Decimal;
        TotalVATBase: Decimal;
        TotalVATBaseACY: Decimal;
    begin
        if not ApplicationAreaMgmt.IsSalesTaxEnabled then
            if (ServiceLine."Gen. Bus. Posting Group" <> GenPostingSetup."Gen. Bus. Posting Group") or
               (ServiceLine."Gen. Prod. Posting Group" <> GenPostingSetup."Gen. Prod. Posting Group")
            then
                GenPostingSetup.Get(ServiceLine."Gen. Bus. Posting Group", ServiceLine."Gen. Prod. Posting Group");

        InvPostingBuffer[1].PrepareService(ServiceLine);
        TotalVAT := ServiceLine."Amount Including VAT" - ServiceLine.Amount;
        TotalVATACY := ServiceLineACY."Amount Including VAT" - ServiceLineACY.Amount;
        TotalAmount := ServiceLine.Amount;
        TotalAmountACY := ServiceLineACY.Amount;
        TotalVATBase := ServiceLine."VAT Base Amount";
        TotalVATBaseACY := ServiceLineACY."VAT Base Amount";

        if SalesSetup."Discount Posting" in
           [SalesSetup."Discount Posting"::"Invoice Discounts", SalesSetup."Discount Posting"::"All Discounts"]
        then begin
            if ServiceLine."VAT Calculation Type" = ServiceLine."VAT Calculation Type"::"Reverse Charge VAT" then
                InvPostingBuffer[1].CalcDiscountNoVAT(
                  -ServiceLine."Inv. Discount Amount", -ServiceLineACY."Inv. Discount Amount")
            else
                InvPostingBuffer[1].CalcDiscount(
                  ServiceHeader."Prices Including VAT", -ServiceLine."Inv. Discount Amount", -ServiceLineACY."Inv. Discount Amount");
            if (InvPostingBuffer[1].Amount <> 0) or (InvPostingBuffer[1]."Amount (ACY)" <> 0) then begin
                InvPostingBuffer[1].SetAccount(
                  GenPostingSetup.GetSalesInvDiscAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                InvPostingBuffer[1].UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                if ServiceLine."Line Discount %" = 100 then begin
                    InvPostingBuffer[1]."VAT Base Amount" := 0;
                    InvPostingBuffer[1]."VAT Base Amount (ACY)" := 0;
                    InvPostingBuffer[1]."VAT Amount" := 0;
                    InvPostingBuffer[1]."VAT Amount (ACY)" := 0;
                end;
                UpdInvPostingBuffer(InvPostingBuffer, ServiceLine);
            end;
        end;

        if SalesSetup."Discount Posting" in
           [SalesSetup."Discount Posting"::"Line Discounts", SalesSetup."Discount Posting"::"All Discounts"]
        then begin
            if ServiceLine."VAT Calculation Type" = ServiceLine."VAT Calculation Type"::"Reverse Charge VAT" then
                InvPostingBuffer[1].CalcDiscountNoVAT(
                  -ServiceLine."Line Discount Amount", -ServiceLineACY."Line Discount Amount")
            else
                InvPostingBuffer[1].CalcDiscount(
                  ServiceHeader."Prices Including VAT", -ServiceLine."Line Discount Amount", -ServiceLineACY."Line Discount Amount");
            if (InvPostingBuffer[1].Amount <> 0) or (InvPostingBuffer[1]."Amount (ACY)" <> 0) then begin
                InvPostingBuffer[1].SetAccount(
                  GenPostingSetup.GetSalesLineDiscAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                InvPostingBuffer[1].UpdateVATBase(TotalVATBase, TotalVATBaseACY);
                UpdInvPostingBuffer(InvPostingBuffer, ServiceLine);
            end;
        end;

        InvPostingBuffer[1].SetAmounts(
          TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, ServiceLine."VAT Difference", TotalVATBase, TotalVATBaseACY);

        case ServiceLine.Type of
            ServiceLine.Type::"G/L Account":
                InvPostingBuffer[1].SetAccount(ServiceLine."No.", TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
            ServiceLine.Type::Cost:
                begin
                    ServCost.Get(ServiceLine."No.");
                    InvPostingBuffer[1].SetAccount(ServCost."Account No.", TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
                end
            else
                if ServiceLine."Document Type" = ServiceLine."Document Type"::"Credit Memo" then
                    InvPostingBuffer[1].SetAccount(
                      GenPostingSetup.GetSalesCrMemoAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY)
                else
                    InvPostingBuffer[1].SetAccount(
                      GenPostingSetup.GetSalesAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY);
        end;
        InvPostingBuffer[1].UpdateVATBase(TotalVATBase, TotalVATBaseACY);

        OnAfterFillInvoicePostBuffer(InvPostingBuffer[1], ServiceLine, InvPostingBuffer[2], SuppressCommit);

        UpdInvPostingBuffer(InvPostingBuffer, ServiceLine);
    end;

    local procedure UpdInvPostingBuffer(var InvPostingBuffer: array[2] of Record "Invoice Post. Buffer"; ServiceLine: Record "Service Line")
    begin
        InvPostingBuffer[1]."Dimension Set ID" := ServiceLine."Dimension Set ID";
        if InvPostingBuffer[1].Type = InvPostingBuffer[1].Type::"Fixed Asset" then begin
            FALineNo := FALineNo + 1;
            InvPostingBuffer[1]."Fixed Asset Line No." := FALineNo;
        end;

        OnBeforeUpdateInvPostBuffer(InvPostingBuffer[1]);

        InvPostingBuffer[2] := InvPostingBuffer[1];
        if InvPostingBuffer[2].Find then begin
            InvPostingBuffer[2].Amount := InvPostingBuffer[2].Amount + InvPostingBuffer[1].Amount;
            InvPostingBuffer[2]."VAT Amount" :=
              InvPostingBuffer[2]."VAT Amount" + InvPostingBuffer[1]."VAT Amount";
            InvPostingBuffer[2]."VAT Base Amount" :=
              InvPostingBuffer[2]."VAT Base Amount" + InvPostingBuffer[1]."VAT Base Amount";
            InvPostingBuffer[2]."Amount (ACY)" :=
              InvPostingBuffer[2]."Amount (ACY)" + InvPostingBuffer[1]."Amount (ACY)";
            InvPostingBuffer[2]."VAT Amount (ACY)" :=
              InvPostingBuffer[2]."VAT Amount (ACY)" + InvPostingBuffer[1]."VAT Amount (ACY)";
            InvPostingBuffer[2]."VAT Difference" :=
              InvPostingBuffer[2]."VAT Difference" + InvPostingBuffer[1]."VAT Difference";
            InvPostingBuffer[2]."VAT Base Amount (ACY)" :=
              InvPostingBuffer[2]."VAT Base Amount (ACY)" +
              InvPostingBuffer[1]."VAT Base Amount (ACY)";
            InvPostingBuffer[2].Quantity :=
              InvPostingBuffer[2].Quantity + InvPostingBuffer[1].Quantity;
            if not InvPostingBuffer[1]."System-Created Entry" then
                InvPostingBuffer[2]."System-Created Entry" := false;
            InvPostingBuffer[2].Modify();
        end else
            InvPostingBuffer[1].Insert();

        OnAfterUpdateInvPostBuffer(InvPostingBuffer[1]);
    end;

    procedure DivideAmount(QtyType: Option General,Invoicing,Shipping; ServLineQty: Decimal; var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var TempVATAmountLine: Record "VAT Amount Line"; var TempVATAmountLineRemainder: Record "VAT Amount Line")
    var
        ChargeableQty: Decimal;
        LineAmountExpected: Decimal;
        LineDiscountAmountExpected: Decimal;
    begin
        if RoundingLineInserted and (RoundingLineNo = ServiceLine."Line No.") then
            exit;

        OnBeforeDivideAmount(ServiceHeader, ServiceLine, QtyType, ServLineQty, TempVATAmountLine, TempVATAmountLineRemainder);

        with ServiceLine do
            if ServLineQty = 0 then begin
                "Line Amount" := 0;
                "Line Discount Amount" := 0;
                "Inv. Discount Amount" := 0;
                "VAT Base Amount" := 0;
                Amount := 0;
                "Amount Including VAT" := 0;
            end else begin
                if TempVATAmountLine.Get("VAT Identifier", "VAT Calculation Type", "Tax Group Code", false, "Line Amount" >= 0) then;
                if "VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax" then
                    "VAT %" := TempVATAmountLine."VAT %";
                TempVATAmountLineRemainder := TempVATAmountLine;
                if not TempVATAmountLineRemainder.Find then begin
                    TempVATAmountLineRemainder.Init();
                    TempVATAmountLineRemainder.Insert();
                end;

                case QtyType of
                    QtyType::Shipping:
                        if ("Qty. to Consume" <> 0) or (ServLineQty <= MaxQtyToInvoice) then
                            ChargeableQty := ServLineQty
                        else
                            ChargeableQty := MaxQtyToInvoice;
                    QtyType::Invoicing:
                        ChargeableQty := ServLineQty;
                    else
                        ChargeableQty := CalcChargeableQty;
                end;

                LineAmountExpected := Round(ChargeableQty * "Unit Price", Currency."Amount Rounding Precision");
                if AmountsDifferByMoreThanRoundingPrecision(LineAmountExpected, "Line Amount", Currency."Amount Rounding Precision") then
                    "Line Amount" := LineAmountExpected;

                if ServLineQty <> Quantity then begin
                    LineDiscountAmountExpected := Round("Line Amount" * "Line Discount %" / 100, Currency."Amount Rounding Precision");
                    if AmountsDifferByMoreThanRoundingPrecision(LineDiscountAmountExpected, "Line Discount Amount", Currency."Amount Rounding Precision") then
                        "Line Discount Amount" := LineDiscountAmountExpected;
                end;

                "Line Amount" := "Line Amount" - "Line Discount Amount";

                if "Allow Invoice Disc." and (TempVATAmountLine."Inv. Disc. Base Amount" <> 0) then
                    if QtyType = QtyType::Invoicing then
                        "Inv. Discount Amount" := "Inv. Disc. Amount to Invoice"
                    else begin
                        TempVATAmountLineRemainder."Invoice Discount Amount" :=
                          TempVATAmountLineRemainder."Invoice Discount Amount" +
                          TempVATAmountLine."Invoice Discount Amount" * "Line Amount" /
                          TempVATAmountLine."Inv. Disc. Base Amount";
                        "Inv. Discount Amount" :=
                          Round(
                            TempVATAmountLineRemainder."Invoice Discount Amount", Currency."Amount Rounding Precision");
                        TempVATAmountLineRemainder."Invoice Discount Amount" :=
                          TempVATAmountLineRemainder."Invoice Discount Amount" - "Inv. Discount Amount";
                    end;

                if ServiceHeader."Prices Including VAT" then begin
                    if (TempVATAmountLine."Line Amount" - TempVATAmountLine."Invoice Discount Amount" = 0) or
                       ("Line Amount" = 0)
                    then begin
                        TempVATAmountLineRemainder."VAT Amount" := 0;
                        TempVATAmountLineRemainder."Amount Including VAT" := 0;
                    end else begin
                        TempVATAmountLineRemainder."VAT Amount" +=
                          TempVATAmountLine."VAT Amount" * CalcLineAmount / TempVATAmountLine.CalcLineAmount;
                        TempVATAmountLineRemainder."Amount Including VAT" +=
                          TempVATAmountLine."Amount Including VAT" * CalcLineAmount / TempVATAmountLine.CalcLineAmount;
                    end;
                    if "Line Discount %" <> 100 then
                        "Amount Including VAT" :=
                          Round(TempVATAmountLineRemainder."Amount Including VAT", Currency."Amount Rounding Precision")
                    else
                        "Amount Including VAT" := 0;
                    Amount :=
                      Round("Amount Including VAT", Currency."Amount Rounding Precision") -
                      Round(TempVATAmountLineRemainder."VAT Amount", Currency."Amount Rounding Precision");
                    "VAT Base Amount" :=
                      Round(
                        Amount * (1 - ServiceHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
                    TempVATAmountLineRemainder."Amount Including VAT" :=
                      TempVATAmountLineRemainder."Amount Including VAT" - "Amount Including VAT";
                    TempVATAmountLineRemainder."VAT Amount" :=
                      TempVATAmountLineRemainder."VAT Amount" - "Amount Including VAT" + Amount;
                end else
                    if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then begin
                        if "Line Discount %" <> 100 then
                            "Amount Including VAT" := CalcLineAmount
                        else
                            "Amount Including VAT" := 0;
                        Amount := 0;
                        "VAT Base Amount" := 0;
                    end else begin
                        Amount := CalcLineAmount;
                        "VAT Base Amount" :=
                          Round(
                            Amount * (1 - ServiceHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
                        if TempVATAmountLine."VAT Base" = 0 then
                            TempVATAmountLineRemainder."VAT Amount" := 0
                        else
                            TempVATAmountLineRemainder."VAT Amount" +=
                              TempVATAmountLine."VAT Amount" * CalcLineAmount / TempVATAmountLine.CalcLineAmount;
                        if "Line Discount %" <> 100 then
                            "Amount Including VAT" :=
                              Amount + Round(TempVATAmountLineRemainder."VAT Amount", Currency."Amount Rounding Precision")
                        else
                            "Amount Including VAT" := 0;
                        TempVATAmountLineRemainder."VAT Amount" :=
                          TempVATAmountLineRemainder."VAT Amount" - "Amount Including VAT" + Amount;
                    end;

                TempVATAmountLineRemainder.Modify();
            end;

        OnAfterDivideAmount(ServiceHeader, ServiceLine, QtyType, ServLineQty, TempVATAmountLine, TempVATAmountLineRemainder);
    end;

    procedure RoundAmount(ServLineQty: Decimal; var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var TempServiceLine: Record "Service Line"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; var ServiceLineACY: Record "Service Line")
    var
        CurrExchRate: Record "Currency Exchange Rate";
        NoVAT: Boolean;
        UseDate: Date;
    begin
        OnBeforeRoundAmount(ServiceHeader, ServiceLine, ServLineQty);

        with ServiceLine do begin
            IncrAmount(ServiceLine, TotalServiceLine, ServiceHeader."Prices Including VAT");
            Increment(TotalServiceLine."Net Weight", Round(ServLineQty * "Net Weight", UOMMgt.WeightRndPrecision));
            Increment(TotalServiceLine."Gross Weight", Round(ServLineQty * "Gross Weight", UOMMgt.WeightRndPrecision));
            Increment(TotalServiceLine."Unit Volume", Round(ServLineQty * "Unit Volume", UOMMgt.CubageRndPrecision));
            Increment(TotalServiceLine.Quantity, ServLineQty);
            if "Units per Parcel" > 0 then
                Increment(
                  TotalServiceLine."Units per Parcel",
                  Round(ServLineQty / "Units per Parcel", 1, '>'));

            TempServiceLine := ServiceLine;
            ServiceLineACY := ServiceLine;

            if ServiceHeader."Currency Code" <> '' then begin
                if ("Document Type" in ["Document Type"::Quote]) and
                   (ServiceHeader."Posting Date" = 0D)
                then
                    UseDate := WorkDate
                else
                    UseDate := ServiceHeader."Posting Date";

                NoVAT := Amount = "Amount Including VAT";
                "Amount Including VAT" :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      UseDate, ServiceHeader."Currency Code",
                      TotalServiceLine."Amount Including VAT", ServiceHeader."Currency Factor")) -
                  TotalServiceLineLCY."Amount Including VAT";
                if NoVAT then
                    Amount := "Amount Including VAT"
                else
                    Amount :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          UseDate, ServiceHeader."Currency Code",
                          TotalServiceLine.Amount, ServiceHeader."Currency Factor")) -
                      TotalServiceLineLCY.Amount;
                "Line Amount" :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      UseDate, ServiceHeader."Currency Code",
                      TotalServiceLine."Line Amount", ServiceHeader."Currency Factor")) -
                  TotalServiceLineLCY."Line Amount";
                "Line Discount Amount" :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      UseDate, ServiceHeader."Currency Code",
                      TotalServiceLine."Line Discount Amount", ServiceHeader."Currency Factor")) -
                  TotalServiceLineLCY."Line Discount Amount";
                "Inv. Discount Amount" :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      UseDate, ServiceHeader."Currency Code",
                      TotalServiceLine."Inv. Discount Amount", ServiceHeader."Currency Factor")) -
                  TotalServiceLineLCY."Inv. Discount Amount";
                "VAT Difference" :=
                  Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      UseDate, ServiceHeader."Currency Code",
                      TotalServiceLine."VAT Difference", ServiceHeader."Currency Factor")) -
                  TotalServiceLineLCY."VAT Difference";
            end;
            "VAT Base Amount" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  UseDate, ServiceHeader."Currency Code",
                  TotalServiceLine."VAT Base Amount", ServiceHeader."Currency Factor")) -
              TotalServiceLineLCY."VAT Base Amount";

            OnRoundAmountOnBeforeIncrAmount(ServiceLine, TotalServiceLine, TotalServiceLineLCY, UseDate, NoVAT);
            IncrAmount(ServiceLine, TotalServiceLineLCY, ServiceHeader."Prices Including VAT");
            Increment(TotalServiceLineLCY."Unit Cost (LCY)", Round(ServLineQty * "Unit Cost (LCY)"));
        end;
    end;

    procedure ReverseAmount(var ServiceLine: Record "Service Line")
    begin
        with ServiceLine do begin
            "Qty. to Ship" := -"Qty. to Ship";
            "Qty. to Ship (Base)" := -"Qty. to Ship (Base)";
            "Qty. to Invoice" := -"Qty. to Invoice";
            "Qty. to Invoice (Base)" := -"Qty. to Invoice (Base)";
            "Qty. to Consume" := -"Qty. to Consume";
            "Qty. to Consume (Base)" := -"Qty. to Consume (Base)";
            "Line Amount" := -"Line Amount";
            Amount := -Amount;
            "VAT Base Amount" := -"VAT Base Amount";
            "VAT Difference" := -"VAT Difference";
            "Amount Including VAT" := -"Amount Including VAT";
            "Line Discount Amount" := -"Line Discount Amount";
            "Inv. Discount Amount" := -"Inv. Discount Amount";
        end;

        OnAfterReverseAmount(ServiceLine);
    end;

    procedure InvoiceRounding(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var TotalServiceLine: Record "Service Line"; var LastLineRetrieved: Boolean; UseTempData: Boolean; BiggestLineNo: Integer)
    var
        TempServiceLineForCalc: Record "Service Line" temporary;
        RoundingServiceLine: Record "Service Line";
        CustPostingGr: Record "Customer Posting Group";
        InvoiceRoundingAmount: Decimal;
    begin
        Currency.TestField("Invoice Rounding Precision");
        InvoiceRoundingAmount :=
          -Round(
            TotalServiceLine."Amount Including VAT" -
            Round(
              TotalServiceLine."Amount Including VAT",
              Currency."Invoice Rounding Precision",
              Currency.InvoiceRoundingDirection),
            Currency."Amount Rounding Precision");

        OnBeforeInvoiceRoundingAmount(
          ServiceHeader, TotalServiceLine."Amount Including VAT", UseTempData, InvoiceRoundingAmount, SuppressCommit);
        if InvoiceRoundingAmount <> 0 then begin
            CustPostingGr.Get(ServiceHeader."Customer Posting Group");
            with ServiceLine do begin
                Init;
                BiggestLineNo += 10000;
                "System-Created Entry" := true;
                if UseTempData then begin
                    "Line No." := 0;
                    Type := Type::"G/L Account";
                    TempServiceLineForCalc := ServiceLine;
                    TempServiceLineForCalc.Validate("No.", CustPostingGr.GetInvRoundingAccount);
                    ServiceLine := TempServiceLineForCalc;
                end else begin
                    "Line No." := BiggestLineNo;
                    RoundingServiceLine := ServiceLine;
                    RoundingServiceLine.Validate(Type, Type::"G/L Account");
                    RoundingServiceLine.Validate("No.", CustPostingGr.GetInvRoundingAccount);
                    ServiceLine := RoundingServiceLine;
                end;
                "Tax Area Code" := '';
                "Tax Liable" := false;
                Validate(Quantity, 1);
                if ServiceHeader."Prices Including VAT" then
                    Validate("Unit Price", InvoiceRoundingAmount)
                else
                    Validate(
                      "Unit Price",
                      Round(
                        InvoiceRoundingAmount /
                        (1 + (1 - ServiceHeader."VAT Base Discount %" / 100) * "VAT %" / 100),
                        Currency."Amount Rounding Precision"));
                Validate("Amount Including VAT", InvoiceRoundingAmount);
                "Line No." := BiggestLineNo;

                LastLineRetrieved := false;
                RoundingLineIsInserted := true;
                RoundingLineNo := "Line No.";
            end;
        end;
    end;

    local procedure IncrAmount(ServiceLine: Record "Service Line"; var TotalServiceLine: Record "Service Line"; PricesIncludingVAT: Boolean)
    begin
        with ServiceLine do begin
            if PricesIncludingVAT or
               ("VAT Calculation Type" <> "VAT Calculation Type"::"Full VAT")
            then
                Increment(TotalServiceLine."Line Amount", "Line Amount");
            Increment(TotalServiceLine.Amount, Amount);
            Increment(TotalServiceLine."VAT Base Amount", "VAT Base Amount");
            Increment(TotalServiceLine."VAT Difference", "VAT Difference");
            Increment(TotalServiceLine."Amount Including VAT", "Amount Including VAT");
            Increment(TotalServiceLine."Line Discount Amount", "Line Discount Amount");
            Increment(TotalServiceLine."Inv. Discount Amount", "Inv. Discount Amount");
            Increment(TotalServiceLine."Inv. Disc. Amount to Invoice", "Inv. Disc. Amount to Invoice");
        end;

        OnAfterIncrAmount(TotalServiceLine, ServiceLine);
    end;

    local procedure Increment(var Number: Decimal; Number2: Decimal)
    begin
        Number := Number + Number2;
    end;

    procedure RoundingLineInserted(): Boolean
    begin
        exit(RoundingLineIsInserted);
    end;

    procedure GetRoundingLineNo(): Integer
    begin
        exit(RoundingLineNo);
    end;

    procedure SumServiceLines(var NewServHeader: Record "Service Header"; QtyType: Option General,Invoicing,Shipping,Consuming; var NewTotalServLine: Record "Service Line"; var NewTotalServLineLCY: Record "Service Line"; var VATAmount: Decimal; var VATAmountText: Text[30]; var ProfitLCY: Decimal; var ProfitPct: Decimal; var TotalAdjCostLCY: Decimal)
    var
        OldServLine: Record "Service Line";
    begin
        SumServiceLinesTemp(
          NewServHeader, OldServLine, QtyType, NewTotalServLine, NewTotalServLineLCY,
          VATAmount, VATAmountText, ProfitLCY, ProfitPct, TotalAdjCostLCY);
    end;

    procedure SumServiceLinesTemp(var NewServHeader: Record "Service Header"; var OldServLine: Record "Service Line"; QtyType: Option General,Invoicing,Shipping,Consuming; var NewTotalServLine: Record "Service Line"; var NewTotalServLineLCY: Record "Service Line"; var VATAmount: Decimal; var VATAmountText: Text[30]; var ProfitLCY: Decimal; var ProfitPct: Decimal; var TotalAdjCostLCY: Decimal)
    var
        ServHeader: Record "Service Header";
        ServLine: Record "Service Line";
        TempServiceLine: Record "Service Line";
        TotalServiceLine: Record "Service Line";
        TotalServiceLineLCY: Record "Service Line";
        ServiceLineACY: Record "Service Line";
    begin
        if not IsInitialized then
            Initialize(NewServHeader."Currency Code");

        with ServHeader do begin
            ServHeader := NewServHeader;
            SumServiceLines2(ServHeader, ServLine, OldServLine, TempServiceLine,
              TotalServiceLine, TotalServiceLineLCY, ServiceLineACY, QtyType, false, true, TotalAdjCostLCY);

            if (QtyType = QtyType::Shipping) and (OldServLine."Qty. to Consume" <> 0) then begin
                TotalServiceLineLCY.Amount := 0;
                TotalServiceLine."Amount Including VAT" := 0;
                ProfitLCY := 0;
                VATAmount := 0;
            end else begin
                ProfitLCY := TotalServiceLineLCY.Amount - TotalServiceLineLCY."Unit Cost (LCY)";
                VATAmount := TotalServiceLine."Amount Including VAT" - TotalServiceLine.Amount;
            end;

            if TotalServiceLineLCY.Amount = 0 then
                ProfitPct := 0
            else
                ProfitPct := Round(ProfitLCY / TotalServiceLineLCY.Amount * 100, 0.1);
            if TotalServiceLine."VAT %" = 0 then
                VATAmountText := Text016
            else
                VATAmountText := StrSubstNo(Text017, TotalServiceLine."VAT %");
            NewTotalServLine := TotalServiceLine;
            NewTotalServLineLCY := TotalServiceLineLCY;
        end;
    end;

    local procedure SumServiceLines2(var ServHeader: Record "Service Header"; var NewServLine: Record "Service Line"; var OldServLine: Record "Service Line"; var TempServiceLine: Record "Service Line"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; var ServiceLineACY: Record "Service Line"; QtyType: Option General,Invoicing,Shipping,Consuming,ServLineItems,ServLineResources,ServLineCosts; InsertServLine: Boolean; CalcAdCostLCY: Boolean; var TotalAdjCostLCY: Decimal)
    var
        ServLine: Record "Service Line";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CostCalcMgt: Codeunit "Cost Calculation Management";
        ServLineQty: Decimal;
        LastLineRetrieved: Boolean;
        AdjCostLCY: Decimal;
        BiggestLineNo: Integer;
        IsHandled: Boolean;
    begin
        TotalAdjCostLCY := 0;
        if not IsInitialized then
            Initialize(ServHeader."Currency Code");
        TempVATAmountLineRemainder.DeleteAll();
        OldServLine.CalcVATAmountLines(QtyType, ServHeader, OldServLine, TempVATAmountLine, false);
        with ServHeader do begin
            GLSetup.Get();
            SalesSetup.Get();
            GetCurrency("Currency Code", Currency);
            OldServLine.SetRange("Document Type", "Document Type");
            OldServLine.SetRange("Document No.", "No.");

            IsHandled := false;
            OnSumServiceLines2OnBeforeSetTypeFilters(OldServLine, ServHeader, QtyType, IsHandled);
            if not IsHandled then
                case QtyType of
                    QtyType::ServLineItems:
                        OldServLine.SetRange(Type, OldServLine.Type::Item);
                    QtyType::ServLineResources:
                        OldServLine.SetRange(Type, OldServLine.Type::Resource);
                    QtyType::ServLineCosts:
                        OldServLine.SetFilter(Type, '%1|%2', OldServLine.Type::Cost, OldServLine.Type::"G/L Account");
                end;

            RoundingLineIsInserted := false;
            if OldServLine.Find('-') then
                repeat
                    if not RoundingLineInserted then
                        ServLine := OldServLine;
                    case QtyType of
                        QtyType::Invoicing:
                            ServLineQty := ServLine."Qty. to Invoice";
                        QtyType::Consuming:
                            begin
                                ServLineQty := ServLine."Qty. to Consume";
                                ServLine."Unit Price" := 0;
                                ServLine."Inv. Discount Amount" := 0;
                            end;
                        QtyType::Shipping:
                            begin
                                if "Document Type" = "Document Type"::"Credit Memo" then
                                    ServLineQty := ServLine.Quantity
                                else
                                    ServLineQty := ServLine."Qty. to Ship";
                                if OldServLine."Qty. to Consume" <> 0 then begin
                                    ServLine."Unit Price" := 0;
                                    ServLine."Inv. Discount Amount" := 0;
                                    ServLine.Amount := 0;
                                end
                            end;
                        else
                            ServLineQty := ServLine.Quantity;
                    end;

                    DivideAmount(QtyType,
                      ServLineQty,
                      ServHeader,
                      ServLine,
                      TempVATAmountLine,
                      TempVATAmountLineRemainder);

                    ServLine.Quantity := ServLineQty;
                    if ServLineQty <> 0 then begin
                        if (ServLine.Amount <> 0) and not RoundingLineInserted then
                            if TotalServiceLine.Amount = 0 then
                                TotalServiceLine."VAT %" := ServLine."VAT %"
                            else
                                if TotalServiceLine."VAT %" <> ServLine."VAT %" then
                                    TotalServiceLine."VAT %" := 0;
                        RoundAmount(ServLineQty, ServHeader, ServLine, TempServiceLine,
                          TotalServiceLine, TotalServiceLineLCY, ServiceLineACY);

                        if not (QtyType in [QtyType::Shipping]) and
                           not InsertServLine and CalcAdCostLCY
                        then begin
                            AdjCostLCY := CostCalcMgt.CalcServLineCostLCY(ServLine, QtyType);
                            TotalAdjCostLCY := TotalAdjCostLCY + GetServLineAdjCostLCY(ServLine, QtyType, AdjCostLCY);
                        end;

                        ServLine := TempServiceLine;
                    end;
                    if InsertServLine then begin
                        NewServLine := ServLine;
                        if NewServLine.Insert() then;
                    end;
                    if RoundingLineInserted then
                        LastLineRetrieved := true
                    else begin
                        BiggestLineNo := MAX(BiggestLineNo, OldServLine."Line No.");
                        LastLineRetrieved := OldServLine.Next = 0;
                        if LastLineRetrieved and SalesSetup."Invoice Rounding" then
                            InvoiceRounding(ServHeader, ServLine, TotalServiceLine,
                              LastLineRetrieved, true, BiggestLineNo);
                    end;
                until LastLineRetrieved;
        end;
    end;

    local procedure GetCurrency(CurrencyCode: Code[10]; var Currency2: Record Currency)
    begin
        if CurrencyCode = '' then
            Currency2.InitRoundingPrecision
        else begin
            Currency2.Get(CurrencyCode);
            Currency2.TestField("Amount Rounding Precision");
        end;
    end;

    procedure GetServiceLines(var NewServiceHeader: Record "Service Header"; var NewServiceLine: Record "Service Line"; QtyType: Option General,Invoicing,Shipping,Consuming)
    var
        OldServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line";
        TotalServiceLine: Record "Service Line";
        TotalServiceLineLCY: Record "Service Line";
        ServiceLineACY: Record "Service Line";
        TotalAdjCostLCY: Decimal;
    begin
        if not IsInitialized then
            Initialize(NewServiceHeader."Currency Code");

        SumServiceLines2(NewServiceHeader, NewServiceLine,
          OldServiceLine, TempServiceLine, TotalServiceLine, TotalServiceLineLCY, ServiceLineACY,
          QtyType, true, false, TotalAdjCostLCY);
    end;

    procedure "MAX"(number1: Integer; number2: Integer): Integer
    begin
        if number1 > number2 then
            exit(number1);
        exit(number2);
    end;

    local procedure GetServLineAdjCostLCY(ServLine2: Record "Service Line"; QtyType: Option General,Invoicing,Shipping,Consuming,ServLineItems,ServLineResources,ServLineCosts; AdjCostLCY: Decimal): Decimal
    begin
        with ServLine2 do begin
            if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice] then
                AdjCostLCY := -AdjCostLCY;

            case true of
                "Shipment No." <> '':
                    exit(AdjCostLCY);
                (QtyType = QtyType::General) or (QtyType = QtyType::ServLineItems) or
              (QtyType = QtyType::ServLineResources) or (QtyType = QtyType::ServLineCosts):
                    exit(Round("Outstanding Quantity" * "Unit Cost (LCY)") + AdjCostLCY);
                "Document Type" in ["Document Type"::Order, "Document Type"::Invoice]:
                    begin
                        if ("Qty. to Invoice" > "Qty. to Ship") or ("Qty. to Consume" > 0) then
                            exit(Round("Qty. to Ship" * "Unit Cost (LCY)") + AdjCostLCY);
                        exit(Round("Qty. to Invoice" * "Unit Cost (LCY)"));
                    end;
                "Document Type" = "Document Type"::"Credit Memo":
                    exit(Round("Qty. to Invoice" * "Unit Cost (LCY)"));
            end;
        end;
    end;

    procedure GetLastLineNo(ServLine: Record "Service Line"): Integer
    begin
        with ServLine do begin
            SetRange("Document Type", "Document Type");
            SetRange("Document No.", "Document No.");
            if FindLast then;
            exit("Line No.");
        end;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    procedure AmountsDifferByMoreThanRoundingPrecision(Amount1: Decimal; Amount2: Decimal; RoundingPrecision: Decimal): Boolean
    begin
        exit((Abs(Amount1 - Amount2)) > RoundingPrecision);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDivideAmount(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; QtyType: Option General,Invoicing,Shipping; ServLineQty: Decimal; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillInvoicePostBuffer(var InvoicePostBuffer: Record "Invoice Post. Buffer"; ServiceLine: Record "Service Line"; var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIncrAmount(var TotalServiceLine: Record "Service Line"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReverseAmount(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateInvPostBuffer(var InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDivideAmount(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; QtyType: Option General,Invoicing,Shipping; ServLineQty: Decimal; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInvoiceRoundingAmount(var ServiceHeader: Record "Service Header"; var AmountIncludingVAT: Decimal; UseTempData: Boolean; var InvoiceRoundingAmount: Decimal; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRoundAmount(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; ServLineQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateInvPostBuffer(var InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRoundAmountOnBeforeIncrAmount(var ServiceLine: Record "Service Line"; TotalServiceLine: Record "Service Line"; TotalServiceLineLCY: Record "Service Line"; UseDate: Date; NoVAT: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSumServiceLines2OnBeforeSetTypeFilters(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; QtyType: Option; var IsHandled: Boolean)
    begin
    end;
}

