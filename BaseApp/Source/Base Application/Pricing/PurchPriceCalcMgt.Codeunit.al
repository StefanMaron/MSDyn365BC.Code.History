#if not CLEAN21
codeunit 7010 "Purch. Price Calc. Mgt."
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
    ObsoleteTag = '16.0';

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        Vend: Record Vendor;
        ResCost: Record "Resource Cost";
        Currency: Record Currency;
        TempPurchPrice: Record "Purchase Price" temporary;
        TempPurchLineDisc: Record "Purchase Line Discount" temporary;
        LineDiscPerCent: Decimal;
        Qty: Decimal;
        QtyPerUOM: Decimal;
        VATPerCent: Decimal;
        PricesInclVAT: Boolean;
        VATBusPostingGr: Code[20];
        PricesInCurrency: Boolean;
        PriceInSKU: Boolean;
        CurrencyFactor: Decimal;
        ExchRateDate: Date;
        FoundPurchPrice: Boolean;
        DateCaption: Text[30];
        Text000: Label '%1 is less than %2 in the %3.';
        Text001: Label 'The %1 in the %2 must be same as in the %3.';

    procedure FindPurchLinePrice(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; CalledByFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindPurchLinePrice(PurchLine, PurchHeader, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        with PurchLine do begin
            SetCurrency(
              PurchHeader."Currency Code", PurchHeader."Currency Factor", PurchHeaderExchDate(PurchHeader));
            SetVAT(PurchHeader."Prices Including VAT", "VAT %", "VAT Bus. Posting Group");
            SetUoM(Abs(Quantity), "Qty. per Unit of Measure");
            SetLineDisc("Line Discount %");

            TestField("Qty. per Unit of Measure");
            if PricesInCurrency then
                PurchHeader.TestField("Currency Factor");

            case Type of
                Type::Item:
                    begin
                        Item.Get("No.");
                        Vend.Get("Pay-to Vendor No.");
                        PriceInSKU := SKU.Get("Location Code", "No.", "Variant Code");
                        PurchLinePriceExists(PurchHeader, PurchLine, false);
                        CalcBestDirectUnitCost(TempPurchPrice);
                        if (FoundPurchPrice or
                            not ((CalledByFieldNo = FieldNo("Job No.")) or (CalledByFieldNo = FieldNo("Job Task No.")) or
                                 (CalledByFieldNo = FieldNo(Quantity)) or
                                 ((CalledByFieldNo = FieldNo("Variant Code")) and not PriceInSKU))) and
                           ("Prepmt. Amt. Inv." = 0)
                        then
                            "Direct Unit Cost" := TempPurchPrice."Direct Unit Cost";
                    end;
                Type::Resource:
                    begin
                        ResCost.Init();
                        ResCost.Code := "No.";
                        ResCost."Work Type Code" := '';
                        OnFindPurchLinePriceOnBeforeRunResourceFindCost(ResCost);
                        CODEUNIT.Run(CODEUNIT::"Resource-Find Cost", ResCost);
                        ConvertPriceLCYToFCY("Currency Code", ResCost."Unit Cost");
                        "Direct Unit Cost" :=
                          Round(ResCost."Direct Unit Cost" * "Qty. per Unit of Measure", Currency."Unit-Amount Rounding Precision");
                    end;
            end;
            OnAfterFindPurchLinePrice(PurchLine, PurchHeader, TempPurchPrice, CalledByFieldNo, PriceInSKU, FoundPurchPrice);
        end;
    end;

    procedure FindItemJnlLinePrice(var ItemJnlLine: Record "Item Journal Line"; CalledByFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindItemJnlLinePrice(ItemJnlLine, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        with ItemJnlLine do begin
            TestField("Qty. per Unit of Measure");
            SetCurrency('', 0, 0D);
            SetVAT(false, 0, '');
            SetUoM(Abs(Quantity), "Qty. per Unit of Measure");

            Item.Get("Item No.");
            PriceInSKU := SKU.Get("Location Code", "Item No.", "Variant Code");

            FindPurchPrice(
              TempPurchPrice, '', "Item No.", "Variant Code",
              "Unit of Measure Code", '', "Posting Date", false);

            OnFindItemJnlLinePriceOnBeforeCalcBestDirectUnitCost(ItemJnlLine, TempPurchPrice);
            CalcBestDirectUnitCost(TempPurchPrice);

            if FoundPurchPrice or
               not ((CalledByFieldNo = FieldNo(Quantity)) or
                    ((CalledByFieldNo = FieldNo("Variant Code")) and not PriceInSKU))
            then
                "Unit Amount" := TempPurchPrice."Direct Unit Cost";
        end;
    end;

    procedure FindReqLinePrice(var ReqLine: Record "Requisition Line"; CalledByFieldNo: Integer)
    var
        VendorNo: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindReqLinePriceOnBeforeWith(ReqLine, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        with ReqLine do
            if Type = Type::Item then begin
                if not Vend.Get("Vendor No.") then
                    Vend.Init()
                else
                    if Vend."Pay-to Vendor No." <> '' then
                        if not Vend.Get(Vend."Pay-to Vendor No.") then
                            Vend.Init();
                if Vend."No." <> '' then
                    VendorNo := Vend."No."
                else
                    VendorNo := "Vendor No.";

                SetCurrency("Currency Code", "Currency Factor", "Order Date");
                SetVAT(Vend."Prices Including VAT", 0, '');
                SetUoM(Abs(Quantity), "Qty. per Unit of Measure");

                TestField("Qty. per Unit of Measure");
                if PricesInCurrency then
                    TestField("Currency Factor");

                Item.Get("No.");
                PriceInSKU := SKU.Get("Location Code", "No.", "Variant Code");

                IsHandled := false;
                OnBeforeFindReqLinePrice(TempPurchPrice, ReqLine, IsHandled);
                if not IsHandled then
                    FindPurchPrice(
                      TempPurchPrice, VendorNo, "No.", "Variant Code",
                      "Unit of Measure Code", "Currency Code", "Order Date", false);
                CalcBestDirectUnitCost(TempPurchPrice);

                if FoundPurchPrice or
                   not ((CalledByFieldNo = FieldNo(Quantity)) or
                        ((CalledByFieldNo = FieldNo("Variant Code")) and not PriceInSKU))
                then
                    "Direct Unit Cost" := TempPurchPrice."Direct Unit Cost";
            end;

        OnAfterFindReqLinePrice(ReqLine, TempPurchPrice, CalledByFieldNo);
    end;

    procedure FindInvtDocLinePrice(var InvtDocLine: Record "Invt. Document Line"; CalledByFieldNo: Integer)
    begin
        with InvtDocLine do begin
            TestField("Qty. per Unit of Measure");
            SetCurrency('', 0, 0D);
            SetVAT(false, 0, '');
            SetUoM(Abs(Quantity), "Qty. per Unit of Measure");

            Item.Get("Item No.");
            PriceInSKU := SKU.Get("Location Code", "Item No.", "Variant Code");

            FindPurchPrice(
              TempPurchPrice, '', "Item No.", "Variant Code",
              "Unit of Measure Code", '', "Posting Date", false);
            CalcBestDirectUnitCost(TempPurchPrice);

            if FoundPurchPrice or
               not ((CalledByFieldNo = FieldNo(Quantity)) or
                    (((CalledByFieldNo = FieldNo("Variant Code")) and not PriceInSKU)))
            then
                "Unit Amount" := TempPurchPrice."Direct Unit Cost";
        end;
    end;

    procedure FindPurchLineLineDisc(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindPurchLineLineDisc(PurchLine, PurchHeader, IsHandled);
        if IsHandled then
            exit;

        with PurchLine do begin
            SetCurrency(PurchHeader."Currency Code", 0, 0D);
            SetUoM(Abs(Quantity), "Qty. per Unit of Measure");

            TestField("Qty. per Unit of Measure");

            if Type = Type::Item then begin
                PurchLineLineDiscExists(PurchHeader, PurchLine, false);
                CalcBestLineDisc(TempPurchLineDisc);

                "Line Discount %" := TempPurchLineDisc."Line Discount %";
            end;

            OnAfterFindPurchLineLineDisc(PurchLine, PurchHeader, TempPurchLineDisc);
        end;
    end;

    procedure FindStdItemJnlLinePrice(var StdItemJnlLine: Record "Standard Item Journal Line"; CalledByFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindStdItemJnlLinePrice(StdItemJnlLine, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        with StdItemJnlLine do begin
            TestField("Qty. per Unit of Measure");
            SetCurrency('', 0, 0D);
            SetVAT(false, 0, '');
            SetUoM(Abs(Quantity), "Qty. per Unit of Measure");

            Item.Get("Item No.");
            PriceInSKU := SKU.Get("Location Code", "Item No.", "Variant Code");

            FindPurchPrice(
              TempPurchPrice, '', "Item No.", "Variant Code",
              "Unit of Measure Code", '', WorkDate(), false);
            CalcBestDirectUnitCost(TempPurchPrice);

            if FoundPurchPrice or
               not ((CalledByFieldNo = FieldNo(Quantity)) or
                    ((CalledByFieldNo = FieldNo("Variant Code")) and not PriceInSKU))
            then
                "Unit Amount" := TempPurchPrice."Direct Unit Cost";
        end;
    end;

    procedure FindReqLineDisc(var ReqLine: Record "Requisition Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindReqLineDiscOnBeforeWith(ReqLine, IsHandled);
        if IsHandled then
            exit;

        with ReqLine do begin
            SetCurrency("Currency Code", 0, 0D);
            SetUoM(Abs(Quantity), "Qty. per Unit of Measure");

            TestField("Qty. per Unit of Measure");

            if Type = Type::Item then begin
                IsHandled := false;
                OnBeforeFindReqLineDisc(ReqLine, TempPurchLineDisc, IsHandled);
                if not IsHandled then
                    FindPurchLineDisc(
                      TempPurchLineDisc, "Vendor No.", "No.", "Variant Code",
                      "Unit of Measure Code", "Currency Code", "Order Date", false,
                      "Qty. per Unit of Measure", Abs(Quantity));
                OnAfterFindReqLineDisc(ReqLine);
                CalcBestLineDisc(TempPurchLineDisc);

                "Line Discount %" := TempPurchLineDisc."Line Discount %";
            end;
        end;
    end;

    procedure CalcBestDirectUnitCost(var PurchPrice: Record "Purchase Price")
    var
        BestPurchPrice: Record "Purchase Price";
        BestPurchPriceFound: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcBestDirectUnitCost(PurchPrice, BestPurchPrice, BestPurchPriceFound, IsHandled);
        if IsHandled then
            exit;

        with PurchPrice do begin
            FoundPurchPrice := Find('-');
            if FoundPurchPrice then
                repeat
                    if IsInMinQty("Unit of Measure Code", "Minimum Quantity") then begin
                        OnCalcBestDirectUnitCostOnBeforeConvertPriceToVAT(PurchPrice);
                        ConvertPriceToVAT(
                          Vend."Prices Including VAT", Item."VAT Prod. Posting Group",
                          Vend."VAT Bus. Posting Group", "Direct Unit Cost");
                        ConvertPriceToUoM("Unit of Measure Code", "Direct Unit Cost");
                        ConvertPriceLCYToFCY("Currency Code", "Direct Unit Cost");

                        case true of
                            ((BestPurchPrice."Currency Code" = '') and ("Currency Code" <> '')) or
                            ((BestPurchPrice."Variant Code" = '') and ("Variant Code" <> '')):
                                begin
                                    BestPurchPrice := PurchPrice;
                                    BestPurchPriceFound := true;
                                end;
                            ((BestPurchPrice."Currency Code" = '') or ("Currency Code" <> '')) and
                          ((BestPurchPrice."Variant Code" = '') or ("Variant Code" <> '')):
                                if (BestPurchPrice."Direct Unit Cost" = 0) or
                                   (CalcLineAmount(BestPurchPrice) > CalcLineAmount(PurchPrice))
                                then begin
                                    BestPurchPrice := PurchPrice;
                                    BestPurchPriceFound := true;
                                end;
                        end;
                    end;
                until Next() = 0;
        end;
        IsHandled := false;
        OnAfterCalcBestDirectUnitCostFound(PurchPrice, BestPurchPriceFound, IsHandled);
        if IsHandled then
            exit;

        // No price found in agreement
        if not BestPurchPriceFound then begin
            IsHandled := false;
            OnCalcBestDirectUnitCostOnBeforeNoPriceFound(BestPurchPrice, Item, IsHandled);
            if not IsHandled then begin
                PriceInSKU := PriceInSKU and (SKU."Last Direct Cost" <> 0);
                if PriceInSKU then
                    BestPurchPrice."Direct Unit Cost" := SKU."Last Direct Cost"
                else
                    BestPurchPrice."Direct Unit Cost" := Item."Last Direct Cost";
            end;
            ConvertPriceToVAT(false, Item."VAT Prod. Posting Group", '', BestPurchPrice."Direct Unit Cost");
            ConvertPriceToUoM('', BestPurchPrice."Direct Unit Cost");
            ConvertPriceLCYToFCY('', BestPurchPrice."Direct Unit Cost");
            OnCalcBestDirectUnitCostOnAfterSetUnitCost(BestPurchPrice);
        end;

        PurchPrice := BestPurchPrice;
    end;

    procedure CalcBestLineDisc(var PurchLineDisc: Record "Purchase Line Discount")
    var
        BestPurchLineDisc: Record "Purchase Line Discount";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcBestLineDisc(PurchLineDisc, Item, IsHandled);
        if IsHandled then
            exit;

        with PurchLineDisc do
            if Find('-') then
                repeat
                    if IsInMinQty("Unit of Measure Code", "Minimum Quantity") then
                        case true of
                            ((BestPurchLineDisc."Currency Code" = '') and ("Currency Code" <> '')) or
                          ((BestPurchLineDisc."Variant Code" = '') and ("Variant Code" <> '')):
                                BestPurchLineDisc := PurchLineDisc;
                            ((BestPurchLineDisc."Currency Code" = '') or ("Currency Code" <> '')) and
                          ((BestPurchLineDisc."Variant Code" = '') or ("Variant Code" <> '')):
                                if BestPurchLineDisc."Line Discount %" < "Line Discount %" then
                                    BestPurchLineDisc := PurchLineDisc;
                        end;
                until Next() = 0;

        OnAfterCalcBestLineDisc(PurchLineDisc, BestPurchLineDisc);
        PurchLineDisc := BestPurchLineDisc;
    end;

    procedure FindPurchPrice(var ToPurchPrice: Record "Purchase Price"; VendorNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UOM: Code[10]; CurrencyCode: Code[10]; StartingDate: Date; ShowAll: Boolean)
    var
        FromPurchPrice: Record "Purchase Price";
    begin
        OnBeforeFindPurchPrice(
          ToPurchPrice, FromPurchPrice, VendorNo, ItemNo, VariantCode, UOM, CurrencyCode, StartingDate, ShowAll, Qty, QtyPerUOM);

        with FromPurchPrice do begin
            SetRange("Item No.", ItemNo);
            SetRange("Vendor No.", VendorNo);
            SetFilter("Ending Date", '%1|>=%2', 0D, StartingDate);
            SetFilter("Variant Code", '%1|%2', VariantCode, '');
            if not ShowAll then begin
                SetRange("Starting Date", 0D, StartingDate);
                SetFilter("Currency Code", '%1|%2', CurrencyCode, '');
                SetFilter("Unit of Measure Code", '%1|%2', UOM, '');
            end;

            ToPurchPrice.Reset();
            ToPurchPrice.DeleteAll();
            if Find('-') then
                repeat
                    ToPurchPrice := FromPurchPrice;
                    ToPurchPrice.Insert();
                until Next() = 0;
        end;

        OnAfterFindPurchPrice(
          ToPurchPrice, FromPurchPrice, VendorNo, ItemNo, VariantCode, UOM, CurrencyCode, StartingDate, ShowAll, Qty, QtyPerUOM);
    end;

    procedure FindPurchLineDisc(var ToPurchLineDisc: Record "Purchase Line Discount"; VendorNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UOM: Code[10]; CurrencyCode: Code[10]; StartingDate: Date; ShowAll: Boolean; QuantityPerUoM: Decimal; Quantity: Decimal)
    var
        FromPurchLineDisc: Record "Purchase Line Discount";
    begin
        OnBeforeFindPurchLineDsic(ToPurchLineDisc, VendorNo, ItemNo, VariantCode, UOM, CurrencyCode, StartingDate, ShowAll, QuantityPerUoM, Quantity);
        with FromPurchLineDisc do begin
            SetRange("Item No.", ItemNo);
            SetRange("Vendor No.", VendorNo);
            SetFilter("Ending Date", '%1|>=%2', 0D, StartingDate);
            SetFilter("Variant Code", '%1|%2', VariantCode, '');
            OnFindPurchLineDiscOnAfterSetFilters(FromPurchLineDisc);
            if not ShowAll then begin
                SetRange("Starting Date", 0D, StartingDate);
                SetFilter("Currency Code", '%1|%2', CurrencyCode, '');
                SetFilter("Unit of Measure Code", '%1|%2', UOM, '');
            end;

            ToPurchLineDisc.Reset();
            ToPurchLineDisc.DeleteAll();

            if Find('-') then
                repeat
                    ToPurchLineDisc := FromPurchLineDisc;
                    ToPurchLineDisc.Insert();
                until Next() = 0;
        end;

        OnAfterFindPurchLineDisc(ToPurchLineDisc, FromPurchLineDisc, ItemNo, QuantityPerUoM, Quantity, ShowAll);
    end;

    procedure SetCurrency(CurrencyCode2: Code[10]; CurrencyFactor2: Decimal; ExchRateDate2: Date)
    begin
        PricesInCurrency := CurrencyCode2 <> '';
        if PricesInCurrency then begin
            Currency.Get(CurrencyCode2);
            Currency.TestField("Unit-Amount Rounding Precision");
            CurrencyFactor := CurrencyFactor2;
            ExchRateDate := ExchRateDate2;
        end else
            GLSetup.Get();
        OnAfterSetCurrency(CurrencyFactor, ExchRateDate, PricesInCurrency, PricesInclVAT, VATPerCent, VATBusPostingGr, DateCaption, PriceInSKU, FoundPurchPrice);
    end;

    procedure SetVAT(PriceInclVAT2: Boolean; VATPerCent2: Decimal; VATBusPostingGr2: Code[20])
    begin
        PricesInclVAT := PriceInclVAT2;
        VATPerCent := VATPerCent2;
        VATBusPostingGr := VATBusPostingGr2;
    end;

    procedure SetUoM(Qty2: Decimal; QtyPerUoM2: Decimal)
    begin
        Qty := Qty2;
        QtyPerUOM := QtyPerUoM2;
    end;

    procedure SetLineDisc(LineDiscPerCent2: Decimal)
    begin
        LineDiscPerCent := LineDiscPerCent2;
    end;

    local procedure IsInMinQty(UnitofMeasureCode: Code[10]; MinQty: Decimal) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsInMinQty(Item, UnitofMeasureCode, MinQty, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if UnitofMeasureCode = '' then
            exit(MinQty <= QtyPerUOM * Qty);
        exit(MinQty <= Qty);
    end;

    local procedure ConvertPriceToVAT(FromPriceInclVAT: Boolean; FromVATProdPostingGr: Code[20]; FromVATBusPostingGr: Code[20]; var UnitPrice: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        IsHandled: Boolean;
    begin
        if FromPriceInclVAT then begin
            if not VATPostingSetup.Get(FromVATBusPostingGr, FromVATProdPostingGr) then
                VATPostingSetup.Init();

            IsHandled := false;
            OnBeforeConvertPriceToVAT(VATPostingSetup, VATBusPostingGr, FromVATBusPostingGr, UnitPrice, PricesInclVAT, IsHandled);
            if IsHandled then
                exit;

            if PricesInclVAT then begin
                if VATBusPostingGr <> FromVATBusPostingGr then
                    UnitPrice := UnitPrice * (100 + VATPerCent) / (100 + VATPostingSetup."VAT %");
            end else
                UnitPrice := UnitPrice / (1 + VATPostingSetup."VAT %" / 100);
        end else
            if PricesInclVAT then
                UnitPrice := UnitPrice * (1 + VATPerCent / 100);
    end;

    local procedure ConvertPriceToUoM(UnitOfMeasureCode: Code[10]; var UnitPrice: Decimal)
    begin
        if UnitOfMeasureCode = '' then
            UnitPrice := UnitPrice * QtyPerUOM;
    end;

    procedure ConvertPriceLCYToFCY(CurrencyCode: Code[10]; var UnitPrice: Decimal)
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        if PricesInCurrency then begin
            if CurrencyCode = '' then
                UnitPrice :=
                  CurrExchRate.ExchangeAmtLCYToFCY(ExchRateDate, Currency.Code, UnitPrice, CurrencyFactor);
            UnitPrice := Round(UnitPrice, Currency."Unit-Amount Rounding Precision");
        end else
            UnitPrice := Round(UnitPrice, GLSetup."Unit-Amount Rounding Precision");
    end;

    local procedure CalcLineAmount(PurchPrice: Record "Purchase Price") Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcLineAmount(PurchPrice, LineDiscPerCent, Result, IsHandled);
        if IsHandled then
            exit(Result);

        with PurchPrice do
            exit("Direct Unit Cost" * (1 - LineDiscPerCent / 100));
    end;

    [Scope('OnPrem')]
    procedure PurchLinePriceExists(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; ShowAll: Boolean): Boolean
    var
        IsHandled: Boolean;
    begin
        with PurchLine do
            if (Type = Type::Item) and Item.Get("No.") then begin
                IsHandled := false;
                OnBeforePurchLinePriceExists(PurchLine, PurchHeader, TempPurchPrice, ShowAll, IsHandled, DateCaption);
                if not IsHandled then
                    FindPurchPrice(
                      TempPurchPrice, "Pay-to Vendor No.", "No.", "Variant Code", "Unit of Measure Code",
                      PurchHeader."Currency Code", PurchHeaderStartDate(PurchHeader, DateCaption), ShowAll);
                OnAfterPurchLinePriceExists(PurchLine);
                exit(TempPurchPrice.Find('-'));
            end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure PurchLineLineDiscExists(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; ShowAll: Boolean): Boolean
    var
        IsHandled: Boolean;
    begin
        with PurchLine do
            if (Type = Type::Item) and Item.Get("No.") then begin
                IsHandled := false;
                OnBeforePurchLineLineDiscExists(PurchLine, PurchHeader, TempPurchLineDisc, ShowAll, IsHandled, DateCaption);
                if not IsHandled then
                    FindPurchLineDisc(
                      TempPurchLineDisc, "Pay-to Vendor No.", "No.", "Variant Code", "Unit of Measure Code",
                      PurchHeader."Currency Code", PurchHeaderStartDate(PurchHeader, DateCaption), ShowAll,
                      "Qty. per Unit of Measure", Quantity);
                OnAfterPurchLineLineDiscExists(PurchLine);
                exit(TempPurchLineDisc.Find('-'));
            end;
        exit(false);
    end;

    local procedure PurchHeaderExchDate(var PurchHeader: Record "Purchase Header"): Date
    begin
        with PurchHeader do begin
            if "Posting Date" <> 0D then
                exit("Posting Date");
            exit(WorkDate());
        end;
    end;

    local procedure PurchHeaderStartDate(var PurchHeader: Record "Purchase Header"; var DateCaption: Text[30]) StartDate: Date
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchHeaderStartDate(PurchHeader, DateCaption, StartDate, IsHandled);
        if IsHandled then
            exit(StartDate);

        with PurchHeader do
            if "Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"] then begin
                DateCaption := FieldCaption("Posting Date");
                exit("Posting Date")
            end else begin
                DateCaption := FieldCaption("Order Date");
                exit("Order Date");
            end;
    end;

    procedure FindJobPlanningLinePrice(var JobPlanningLine: Record "Job Planning Line"; CalledByFieldNo: Integer)
    var
        JTHeader: Record Job;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindJobPlanningLinePrice(JobPlanningLine, CalledByFieldNo, IsHandled);
        if not IsHandled then
            with JobPlanningLine do begin
                SetCurrency("Currency Code", "Currency Factor", "Planning Date");
                SetVAT(false, 0, '');
                SetUoM(Abs(Quantity), "Qty. per Unit of Measure");

                TestField("Qty. per Unit of Measure");

                case Type of
                    Type::Item:
                        begin
                            Item.Get("No.");
                            PriceInSKU := SKU.Get('', "No.", "Variant Code");
                            JTHeader.Get("Job No.");

                            FindPurchPrice(
                              TempPurchPrice, '', "No.", "Variant Code", "Unit of Measure Code", '', "Planning Date", false);
                            PricesInCurrency := false;
                            GLSetup.Get();
                            CalcBestDirectUnitCost(TempPurchPrice);
                            SetCurrency("Currency Code", "Currency Factor", "Planning Date");

                            if FoundPurchPrice or
                               not ((CalledByFieldNo = FieldNo(Quantity)) or
                                    ((CalledByFieldNo = FieldNo("Variant Code")) and not PriceInSKU))
                            then
                                "Direct Unit Cost (LCY)" := TempPurchPrice."Direct Unit Cost";
                        end;
                    Type::Resource:
                        begin
                            ResCost.Init();
                            ResCost.Code := "No.";
                            ResCost."Work Type Code" := "Work Type Code";
                            OnFindJobPlanningLinePriceOnBeforeResourceFindCost(JobPlanningLine, ResCost);
                            CODEUNIT.Run(CODEUNIT::"Resource-Find Cost", ResCost);
                            JobPlanningLine.AfterResourceFindCost(ResCost);
                            OnAfterJobPlanningLineFindResCost(JobPlanningLine, CalledByFieldNo, ResCost);
                            ConvertPriceLCYToFCY("Currency Code", ResCost."Unit Cost");
                            "Direct Unit Cost (LCY)" := Round(ResCost."Direct Unit Cost" * "Qty. per Unit of Measure",
                                Currency."Unit-Amount Rounding Precision");
                            Validate("Unit Cost (LCY)", Round(ResCost."Unit Cost" * "Qty. per Unit of Measure",
                                Currency."Unit-Amount Rounding Precision"));
                        end;
                end;
                Validate("Direct Unit Cost (LCY)");
            end;
        OnAfterFindJobPlanningLinePrice(JobPlanningLine, ResCost);
    end;

    procedure FindJobJnlLinePrice(var JobJnlLine: Record "Job Journal Line"; CalledByFieldNo: Integer)
    var
        Job: Record Job;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindJobJnlLinePrice(JobJnlLine, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        with JobJnlLine do begin
            SetCurrency("Currency Code", "Currency Factor", "Posting Date");
            SetVAT(false, 0, '');
            SetUoM(Abs(Quantity), "Qty. per Unit of Measure");

            TestField("Qty. per Unit of Measure");

            case Type of
                Type::Item:
                    begin
                        Item.Get("No.");
                        PriceInSKU := SKU.Get('', "No.", "Variant Code");
                        Job.Get("Job No.");

                        FindPurchPrice(
                          TempPurchPrice, '', "No.", "Variant Code", "Unit of Measure Code", "Country/Region Code", "Posting Date", false);
                        PricesInCurrency := false;
                        GLSetup.Get();

                        OnFindJobJnlLinePriceOnBeforeCalcBestDirectUnitCost(JobJnlLine, TempPurchPrice);
                        CalcBestDirectUnitCost(TempPurchPrice);
                        SetCurrency("Currency Code", "Currency Factor", "Posting Date");

                        if FoundPurchPrice or
                           not ((CalledByFieldNo = FieldNo(Quantity)) or
                                ((CalledByFieldNo = FieldNo("Variant Code")) and not PriceInSKU))
                        then
                            "Direct Unit Cost (LCY)" := TempPurchPrice."Direct Unit Cost";
                        OnAfterFindJobJnlLinePriceItem(JobJnlLine);
                    end;
                Type::Resource:
                    begin
                        ResCost.Init();
                        ResCost.Code := "No.";
                        ResCost."Work Type Code" := "Work Type Code";
                        OnFindJobJnlLinePriceOnBeforeResourceFindCost(JobJnlLine, ResCost);
                        CODEUNIT.Run(CODEUNIT::"Resource-Find Cost", ResCost);
                        JobJnlLine.AfterResourceFindCost(ResCost);
                        OnAfterJobJnlLineFindResCost(JobJnlLine, CalledByFieldNo, ResCost);
                        ConvertPriceLCYToFCY("Currency Code", ResCost."Unit Cost");
                        "Direct Unit Cost (LCY)" :=
                          Round(ResCost."Direct Unit Cost" * "Qty. per Unit of Measure", Currency."Unit-Amount Rounding Precision");
                        Validate("Unit Cost (LCY)",
                          Round(ResCost."Unit Cost" * "Qty. per Unit of Measure", Currency."Unit-Amount Rounding Precision"));
                        OnAfterFindJobJnlLinePriceResource(JobJnlLine, ResCost);
                    end;
            end;
            OnAfterFindJobJnlLinePrice(JobJnlLine, IsHandled);
            if not IsHandled then
                Validate("Direct Unit Cost (LCY)");
        end;
    end;

    procedure NoOfPurchLinePrice(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; ShowAll: Boolean) ReturnValue: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNoOfPurchLinePrice(PurchHeader, PurchLine, ShowAll, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        if PurchLinePriceExists(PurchHeader, PurchLine, ShowAll) then
            exit(TempPurchPrice.Count);
    end;

    procedure NoOfPurchLineLineDisc(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; ShowAll: Boolean) ReturnValue: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNoOfPurchLineLineDisc(PurchHeader, PurchLine, ShowAll, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        if PurchLineLineDiscExists(PurchHeader, PurchLine, ShowAll) then
            exit(TempPurchLineDisc.Count);
    end;

    procedure GetPurchLinePrice(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPurchLinePrice(PurchHeader, PurchLine, IsHandled);
        if IsHandled then
            exit;

        PurchLinePriceExists(PurchHeader, PurchLine, true);

        with PurchLine do
            if PAGE.RunModal(PAGE::"Get Purchase Price", TempPurchPrice) = ACTION::LookupOK then begin
                SetVAT(PurchHeader."Prices Including VAT", "VAT %", "VAT Bus. Posting Group");
                SetUoM(Abs(Quantity), "Qty. per Unit of Measure");
                SetCurrency(PurchHeader."Currency Code", PurchHeader."Currency Factor", PurchHeaderExchDate(PurchHeader));
                OnGetPurchLinePriceOnAfterLookup(PurchHeader, PurchLine, TempPurchPrice);

                if not IsInMinQty(TempPurchPrice."Unit of Measure Code", TempPurchPrice."Minimum Quantity") then
                    Error(
                      Text000,
                      FieldCaption(Quantity),
                      TempPurchPrice.FieldCaption("Minimum Quantity"),
                      TempPurchPrice.TableCaption());
                if not (TempPurchPrice."Currency Code" in ["Currency Code", '']) then
                    Error(
                      Text001,
                      FieldCaption("Currency Code"),
                      TableCaption,
                      TempPurchPrice.TableCaption());
                if not (TempPurchPrice."Unit of Measure Code" in ["Unit of Measure Code", '']) then
                    Error(
                      Text001,
                      FieldCaption("Unit of Measure Code"),
                      TableCaption,
                      TempPurchPrice.TableCaption());
                if TempPurchPrice."Starting Date" > PurchHeaderStartDate(PurchHeader, DateCaption) then
                    Error(
                      Text000,
                      DateCaption,
                      TempPurchPrice.FieldCaption("Starting Date"),
                      TempPurchPrice.TableCaption());

                ConvertPriceToVAT(
                  PurchHeader."Prices Including VAT", Item."VAT Prod. Posting Group",
                  "VAT Bus. Posting Group", TempPurchPrice."Direct Unit Cost");
                ConvertPriceToUoM(TempPurchPrice."Unit of Measure Code", TempPurchPrice."Direct Unit Cost");
                ConvertPriceLCYToFCY(TempPurchPrice."Currency Code", TempPurchPrice."Direct Unit Cost");

                Validate("Direct Unit Cost", TempPurchPrice."Direct Unit Cost");
            end;

        OnAfterGetPurchLinePrice(PurchHeader, PurchLine, TempPurchPrice, QtyPerUOM);
    end;

    procedure GetPurchLineLineDisc(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPurchLineDisc(PurchHeader, PurchLine, IsHandled);
        if IsHandled then
            exit;

        PurchLineLineDiscExists(PurchHeader, PurchLine, true);

        with PurchLine do
            if PAGE.RunModal(PAGE::"Get Purchase Line Disc.", TempPurchLineDisc) = ACTION::LookupOK then begin
                SetCurrency(PurchHeader."Currency Code", 0, 0D);
                SetUoM(Abs(Quantity), "Qty. per Unit of Measure");
                OnGetPurchLineLineDiscOnAfterLookup(PurchHeader, PurchLine, TempPurchLineDisc);

                if not IsInMinQty(TempPurchLineDisc."Unit of Measure Code", TempPurchLineDisc."Minimum Quantity") then
                    Error(
                      Text000, FieldCaption(Quantity),
                      TempPurchLineDisc.FieldCaption("Minimum Quantity"),
                      TempPurchLineDisc.TableCaption());
                if not (TempPurchLineDisc."Currency Code" in ["Currency Code", '']) then
                    Error(
                      Text001,
                      FieldCaption("Currency Code"),
                      TableCaption,
                      TempPurchLineDisc.TableCaption());
                if not (TempPurchLineDisc."Unit of Measure Code" in ["Unit of Measure Code", '']) then
                    Error(
                      Text001,
                      FieldCaption("Unit of Measure Code"),
                      TableCaption,
                      TempPurchLineDisc.TableCaption());
                if TempPurchLineDisc."Starting Date" > PurchHeaderStartDate(PurchHeader, DateCaption) then
                    Error(
                      Text000,
                      DateCaption,
                      TempPurchLineDisc.FieldCaption("Starting Date"),
                      TempPurchLineDisc.TableCaption());

                Validate("Line Discount %", TempPurchLineDisc."Line Discount %");
            end;

        OnAfterGetPurchLineLineDisc(PurchLine, TempPurchLineDisc);
    end;

    procedure SetItem(ItemNo: Code[20])
    begin
        Item.Get(ItemNo);
    end;

    procedure SetVendor(VendorNo: Code[20])
    begin
        Vend.Get(VendorNo);
    end;

    procedure FindResUnitCost(var ResJournalLine: Record "Res. Journal Line")
    begin
        GLSetup.Get();
        ResCost.Init();
        ResCost.Code := ResJournalLine."Resource No.";
        ResCost."Work Type Code" := ResJournalLine."Work Type Code";
        ResJournalLine.AfterInitResourceCost(ResCost);
        CODEUNIT.Run(CODEUNIT::"Resource-Find Cost", ResCost);
        ResJournalLine.AfterFindResUnitCost(ResCost);
        ResJournalLine."Direct Unit Cost" :=
            Round(ResCost."Direct Unit Cost" * ResJournalLine."Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
        ResJournalLine."Unit Cost" :=
            Round(ResCost."Unit Cost" * ResJournalLine."Qty. per Unit of Measure", GLSetup."Unit-Amount Rounding Precision");
        ResJournalLine.Validate("Unit Cost");
    end;

    procedure FindResUnitCost(var SalesLine: Record "Sales Line")
    begin
        ResCost.Init();
        SalesLine.FindResUnitCostOnAfterInitResCost(ResCost);
        ResCost.Code := SalesLine."No.";
        ResCost."Work Type Code" := SalesLine."Work Type Code";
        CODEUNIT.Run(CODEUNIT::"Resource-Find Cost", ResCost);
        SalesLine.AfterFindResUnitCost(ResCost);
        SalesLine.Validate("Unit Cost (LCY)", ResCost."Unit Cost" * SalesLine."Qty. per Unit of Measure");
    end;

    procedure FindResUnitCost(var ServiceLine: Record "Service Line")
    begin
        ResCost.Init();
        ResCost.Code := ServiceLine."No.";
        ResCost."Work Type Code" := ServiceLine."Work Type Code";
        CODEUNIT.Run(CODEUNIT::"Resource-Find Cost", ResCost);
        ServiceLine.AfterResourseFindCost(ResCost);
        ServiceLine.Validate("Unit Cost (LCY)", ResCost."Unit Cost" * ServiceLine."Qty. per Unit of Measure");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcBestDirectUnitCostFound(var PurchPrice: Record "Purchase Price"; var BestPurchPriceFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcBestLineDisc(var PurchaLineDisc: Record "Purchase Line Discount"; var BestPurchLineDisc: Record "Purchase Line Discount");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindJobJnlLinePrice(var JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindJobPlanningLinePrice(var JobPlanningLine: Record "Job Planning Line"; var ResourceCost: Record "Resource Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindJobJnlLinePriceItem(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindJobJnlLinePriceResource(var JobJournalLine: Record "Job Journal Line"; var ResourceCost: Record "Resource Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindPurchPrice(var ToPurchPrice: Record "Purchase Price"; FromPurchasePrice: Record "Purchase Price"; VendorNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UOM: Code[10]; CurrencyCode: Code[10]; StartingDate: Date; ShowAll: Boolean; Qty: Decimal; QtyPerUOM: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindPurchLinePrice(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var PurchasePrice: Record "Purchase Price"; CalledByFieldNo: Integer; PriceInSKU: Boolean; FoundPurchPrice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindPurchLineDisc(var ToPurchaseLineDiscount: Record "Purchase Line Discount"; var FromPurchaseLineDiscount: Record "Purchase Line Discount"; ItemNo: Code[20]; QuantityPerUoM: Decimal; Quantity: Decimal; ShowAll: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindPurchLineLineDisc(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var TempPurchLineDisc: Record "Purchase Line Discount" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindReqLinePrice(var ReqLine: Record "Requisition Line"; var TempPurchasePrice: Record "Purchase Price" temporary; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindReqLineDisc(var ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPurchLinePrice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var TempPurchasePrice: Record "Purchase Price" temporary; QtyPerUOM: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPurchLineLineDisc(var PurchaseLine: Record "Purchase Line"; var TempPurchLineDisc: Record "Purchase Line Discount");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterJobJnlLineFindResCost(var JobJournalLine: Record "Job Journal Line"; CalledByFieldNo: Integer; var ResourceCost: Record "Resource Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterJobPlanningLineFindResCost(var JobPlanningLine: Record "Job Planning Line"; CalledByFieldNo: Integer; var ResourceCost: Record "Resource Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchLineLineDiscExists(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchLinePriceExists(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCurrency(var CurrencyFactor: Decimal; var ExchRateDate: Date; var PricesInCurrency: Boolean; var PricesInclVAT: Boolean; var VATPerCent: Decimal; var VATBusPostingGr: Code[20]; var DateCaption: Text[30]; var PriceInSKU: Boolean; var FoundPurchPrice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcBestDirectUnitCost(var PurchPrice: Record "Purchase Price"; var BestPurchPrice: Record "Purchase Price"; var BestPurchPriceFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcBestLineDisc(var PurchLineDisc: Record "Purchase Line Discount"; Item: Record Item; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcLineAmount(var PurchasePrice: Record "Purchase Price"; LineDiscPerCent: Decimal; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConvertPriceToVAT(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGr: Code[20]; FromVATBusPostingGr: Code[20]; UnitPrice: Decimal; PricesInclVAT: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindItemJnlLinePrice(var ItemJournalLine: Record "Item Journal Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindJobJnlLinePrice(var JobJnlLine: Record "Job Journal Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindJobPlanningLinePrice(var JobPlanningLine: Record "Job Planning Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindPurchLinePrice(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindPurchLineDsic(var ToPurchLineDisc: Record "Purchase Line Discount"; var VendorNo: Code[20]; var ItemNo: Code[20]; var VariantCode: Code[10]; var UOM: Code[10]; var CurrencyCode: Code[10]; var StartingDate: Date; var ShowAll: Boolean; var QuantityPerUoM: Decimal; var Quantity: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindPurchPrice(var ToPurchPrice: Record "Purchase Price"; var FromPurchasePrice: Record "Purchase Price"; var VendorNo: Code[20]; var ItemNo: Code[20]; var VariantCode: Code[10]; var UOM: Code[10]; var CurrencyCode: Code[10]; var StartingDate: Date; var ShowAll: Boolean; var Qty: Decimal; var QtyPerUOM: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindReqLinePrice(var TempPurchasePrice: Record "Purchase Price" temporary; var ReqLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindReqLinePriceOnBeforeWith(var RequisitionLine: Record "Requisition Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindReqLineDisc(var ReqLine: Record "Requisition Line"; var TempPurchaseLineDiscount: Record "Purchase Line Discount" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindReqLineDiscOnBeforeWith(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindStdItemJnlLinePrice(var StandardItemJnlLine: Record "Standard Item Journal Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPurchLineDisc(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPurchLinePrice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsInMinQty(var Item: Record Item; UnitofMeasureCode: Code[10]; MinQty: Decimal; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNoOfPurchLineLineDisc(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ShowAll: Boolean; var ReturnValue: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNoOfPurchLinePrice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ShowAll: Boolean; var ReturnValue: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchLinePriceExists(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var TempPurchasePrice: Record "Purchase Price" temporary; ShowAll: Boolean; var IsHandled: Boolean; var DateCaption: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchLineLineDiscExists(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var TempPurchLineDisc: Record "Purchase Line Discount" temporary; ShowAll: Boolean; var IsHandled: Boolean; var DateCaption: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchHeaderStartDate(var PurchaseHeader: Record "Purchase Header"; var DateCaption: Text[30]; var StartDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindPurchLineLineDisc(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcBestDirectUnitCostOnAfterSetUnitCost(var PurchasePrice: Record "Purchase Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcBestDirectUnitCostOnBeforeConvertPriceToVAT(var PurchasePrice: Record "Purchase Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcBestDirectUnitCostOnBeforeNoPriceFound(var PurchasePrice: Record "Purchase Price"; Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindJobPlanningLinePriceOnBeforeResourceFindCost(JobPlanningLine: Record "Job Planning Line"; var ResCost: Record "Resource Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindJobJnlLinePriceOnBeforeResourceFindCost(JobJournalLine: Record "Job Journal Line"; var ResCost: Record "Resource Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPurchLinePriceOnAfterLookup(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var TempPurchasePrice: Record "Purchase Price" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPurchLineLineDiscOnAfterLookup(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var TempPurchaseLineDiscount: Record "Purchase Line Discount" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindItemJnlLinePriceOnBeforeCalcBestDirectUnitCost(var ItemJournalLine: Record "Item Journal Line"; var TempPurchasePrice: Record "Purchase Price" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindPurchLineDiscOnAfterSetFilters(var FromPurchLineDisc: Record "Purchase Line Discount");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindPurchLinePriceOnBeforeRunResourceFindCost(var ResCost: record "Resource cost");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindJobJnlLinePriceOnBeforeCalcBestDirectUnitCost(var JobJournalLine: Record "Job Journal Line"; var TempPurchasePrice: Record "Purchase Price" temporary)
    begin
    end;
}
#endif
