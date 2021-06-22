table 39 "Purchase Line"
{
    Caption = 'Purchase Line';
    DrillDownPageID = "Purchase Lines";
    LookupPageID = "Purchase Lines";

    fields
    {
        field(1; "Document Type"; Enum "Purchase Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Buy-from Vendor No."; Code[20])
        {
            Caption = 'Buy-from Vendor No.';
            Editable = false;
            TableRelation = Vendor;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Purchase Header"."No." WHERE("Document Type" = FIELD("Document Type"));
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Type; Enum "Purchase Line Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            var
                TempPurchLine: Record "Purchase Line" temporary;
            begin
                GetPurchHeader;
                TestStatusOpen;

                TestField("Qty. Rcd. Not Invoiced", 0);
                TestField("Quantity Received", 0);
                TestField("Receipt No.", '');

                TestField("Return Qty. Shipped Not Invd.", 0);
                TestField("Return Qty. Shipped", 0);
                TestField("Return Shipment No.", '');

                TestField("Prepmt. Amt. Inv.", 0);

                CheckAssosiatedSalesOrder();
                CheckAssosiatedProdOrder();

                if Type <> xRec.Type then begin
                    case xRec.Type of
                        Type::Item:
                            if Quantity <> 0 then begin
                                PurchHeader.TestField(Status, PurchHeader.Status::Open);
                                ReservePurchLine.VerifyChange(Rec, xRec);
                                CalcFields("Reserved Qty. (Base)");
                                TestField("Reserved Qty. (Base)", 0);
                                WhseValidateSourceLine.PurchaseLineVerifyChange(Rec, xRec);
                                OnValidateTypeOnAfterCheckItem(Rec, xRec);
                            end;
                        Type::"Fixed Asset":
                            if Quantity <> 0 then
                                PurchHeader.TestField(Status, PurchHeader.Status::Open);
                        Type::"Charge (Item)":
                            DeleteChargeChargeAssgnt("Document Type", "Document No.", "Line No.");
                    end;
                    if xRec."Deferral Code" <> '' then
                        DeferralUtilities.RemoveOrSetDeferralSchedule('',
                          DeferralUtilities.GetPurchDeferralDocType, '', '',
                          xRec."Document Type", xRec."Document No.", xRec."Line No.",
                          xRec.GetDeferralAmount(), PurchHeader."Posting Date", '', xRec."Currency Code", true);
                end;
                TempPurchLine := Rec;
                Init;

                if xRec."Line Amount" <> 0 then
                    "Recalculate Invoice Disc." := true;

                Type := TempPurchLine.Type;
                "System-Created Entry" := TempPurchLine."System-Created Entry";
                OnValidateTypeOnCopyFromTempPurchLine(Rec, TempPurchLine);
                Validate("FA Posting Type");

                if Type = Type::Item then
                    "Allow Item Charge Assignment" := true
                else
                    "Allow Item Charge Assignment" := false;
            end;
        }
        field(6; "No."; Code[20])
        {
            CaptionClass = GetCaptionClass(FieldNo("No."));
            Caption = 'No.';
            TableRelation = IF (Type = CONST(" ")) "Standard Text"
            ELSE
            IF (Type = CONST("G/L Account"),
                                     "System-Created Entry" = CONST(false)) "G/L Account" WHERE("Direct Posting" = CONST(true),
                                                                                               "Account Type" = CONST(Posting),
                                                                                               Blocked = CONST(false))
            ELSE
            IF (Type = CONST("G/L Account"),
                                                                                                        "System-Created Entry" = CONST(true)) "G/L Account"
            ELSE
            IF (Type = CONST("Fixed Asset")) "Fixed Asset"
            ELSE
            IF (Type = CONST("Charge (Item)")) "Item Charge"
            ELSE
            IF (Type = CONST(Item),
                                                                                                                 "Document Type" = FILTER(<> "Credit Memo" & <> "Return Order")) Item WHERE(Blocked = CONST(false),
                                                                                                                                                                                       "Purchasing Blocked" = CONST(false))
            ELSE
            IF (Type = CONST(Item),
                                                                                                                                                                                                "Document Type" = FILTER("Credit Memo" | "Return Order")) Item WHERE(Blocked = CONST(false))
            else
            if (Type = const(Resource)) Resource;

            ValidateTableRelation = false;

            trigger OnValidate()
            var
                TempPurchLine: Record "Purchase Line" temporary;
            begin
                GetPurchSetup();

                "No." := FindOrCreateRecordByNo("No.");

                TestStatusOpen();
                TestField("Qty. Rcd. Not Invoiced", 0);
                TestField("Quantity Received", 0);
                TestField("Receipt No.", '');

                TestField("Prepmt. Amt. Inv.", 0);

                TestReturnFieldsZero();

                CheckAssosiatedSalesOrder();
                CheckAssosiatedProdOrder();

                OnValidateNoOnAfterChecks(Rec, xRec, CurrFieldNo);

                if "No." <> xRec."No." then begin
                    if (Quantity <> 0) and ItemExists(xRec."No.") then begin
                        ReservePurchLine.VerifyChange(Rec, xRec);
                        CalcFields("Reserved Qty. (Base)");
                        TestField("Reserved Qty. (Base)", 0);
                        if Type = Type::Item then
                            WhseValidateSourceLine.PurchaseLineVerifyChange(Rec, xRec);
                        OnValidateNoOnAfterVerifyChange(Rec, xRec);
                    end;
                    if Type = Type::Item then
                        DeleteItemChargeAssgnt("Document Type", "Document No.", "Line No.");
                    if Type = Type::"Charge (Item)" then
                        DeleteChargeChargeAssgnt("Document Type", "Document No.", "Line No.");
                end;

                OnValidateNoOnBeforeInitRec(Rec, xRec, CurrFieldNo);
                TempPurchLine := Rec;
                Init;
                if xRec."Line Amount" <> 0 then
                    "Recalculate Invoice Disc." := true;
                Type := TempPurchLine.Type;
                "No." := TempPurchLine."No.";
                OnValidateNoOnCopyFromTempPurchLine(Rec, TempPurchLine);
                if "No." = '' then
                    exit;

                if HasTypeToFillMandatoryFields then begin
                    Quantity := TempPurchLine.Quantity;
                    "Outstanding Qty. (Base)" := TempPurchLine."Outstanding Qty. (Base)";
                end;

                "System-Created Entry" := TempPurchLine."System-Created Entry";

                OnBeforeAssignHeaderValues(Rec, PurchHeader);

                GetPurchHeader;
                InitHeaderDefaults(PurchHeader);
                UpdateLeadTimeFields;
                UpdateDates;

                OnAfterAssignHeaderValues(Rec, PurchHeader);

                case Type of
                    Type::" ":
                        CopyFromStandardText;
                    Type::"G/L Account":
                        CopyFromGLAccount;
                    Type::Item:
                        CopyFromItem;
                    Type::Resource:
                        CopyFromResource();
                    Type::"Fixed Asset":
                        CopyFromFixedAsset;
                    Type::"Charge (Item)":
                        CopyFromItemCharge;
                end;

                OnAfterAssignFieldsForNo(Rec, xRec, PurchHeader);

                if Type <> Type::" " then begin
                    PostingSetupMgt.CheckGenPostingSetupPurchAccount("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
                    PostingSetupMgt.CheckVATPostingSetupPurchAccount("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                end;

                if HasTypeToFillMandatoryFields and not (Type = Type::"Fixed Asset") then
                    Validate("VAT Prod. Posting Group");

                UpdatePrepmtSetupFields;

                if HasTypeToFillMandatoryFields then begin
                    PlanPriceCalcByField(FieldNo("No."));
                    Quantity := xRec.Quantity;
                    OnValidateNoOnAfterAssignQtyFromXRec(Rec, TempPurchLine);
                    Validate("Unit of Measure Code");
                    if Quantity <> 0 then begin
                        InitOutstanding;
                        if IsCreditDocType then
                            InitQtyToShip
                        else
                            InitQtyToReceive;
                    end;
                    UpdateWithWarehouseReceive;
                    if xRec."Job No." <> '' then
                        Validate("Job No.", xRec."Job No.");
                    "Job Line Type" := xRec."Job Line Type";
                    if xRec."Job Task No." <> '' then begin
                        Validate("Job Task No.", xRec."Job Task No.");
                        if "No." = xRec."No." then
                            Validate("Job Planning Line No.", xRec."Job Planning Line No.");
                    end;
                end;

                CreateDim(
                  DimMgt.TypeToTableID3(Type), "No.",
                  DATABASE::Job, "Job No.",
                  DATABASE::"Responsibility Center", "Responsibility Center",
                  DATABASE::"Work Center", "Work Center No.");

                GetPurchHeader;
                UpdateItemReference;
                UpdateDirectUnitCostByField(FieldNo("No."));

                GetDefaultBin;

                if JobTaskIsSet then begin
                    CreateTempJobJnlLine(true);
                    UpdateJobPrices;
                    UpdateDimensionsFromJobTask;
                end;
            end;
        }
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));

            trigger OnValidate()
            var
                Item: Record Item;
                ConfirmManagement: Codeunit "Confirm Management";
                IsHandled: Boolean;
            begin
                TestStatusOpen;

                if "Location Code" <> '' then
                    if IsNonInventoriableItem then begin
                        GetItem(Item);
                        Item.TestField(Type, Item.Type::Inventory);
                    end;
                if xRec."Location Code" <> "Location Code" then begin
                    if "Prepmt. Amt. Inv." <> 0 then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(
                               Text046, FieldCaption("Direct Unit Cost"), FieldCaption("Location Code"), PRODUCTNAME.Full), true)
                        then begin
                            "Location Code" := xRec."Location Code";
                            exit;
                        end;
                    TestField("Qty. Rcd. Not Invoiced", 0);
                    TestField("Receipt No.", '');

                    TestField("Return Qty. Shipped Not Invd.", 0);
                    TestField("Return Shipment No.", '');
                end;

                IsHandled := false;
                OnValidateLocationCodeOnBeforeDropShipmentError(Rec, IsHandled);
                if not IsHandled then
                    if "Drop Shipment" then
                        Error(Text001, FieldCaption("Location Code"), "Sales Order No.");

                IsHandled := false;
                OnValidateLocationCodeOnBeforeSpecialOrderError(Rec, IsHandled);
                if not IsHandled then
                    if "Special Order" then
                        Error(Text001, FieldCaption("Location Code"), "Special Order Sales No.");

                if "Location Code" <> xRec."Location Code" then begin
                    InitItemAppl;
                    if IsInventoriableItem then
                        PostingSetupMgt.CheckInvtPostingSetupInventoryAccount("Location Code", "Posting Group");
                end;

                if (xRec."Location Code" <> "Location Code") and (Quantity <> 0) then begin
                    ReservePurchLine.VerifyChange(Rec, xRec);
                    WhseValidateSourceLine.PurchaseLineVerifyChange(Rec, xRec);
                    UpdateWithWarehouseReceive;
                end;
                "Bin Code" := '';

                if Type = Type::Item then
                    if "Location Code" <> xRec."Location Code" then
                        PlanPriceCalcByField(FieldNo("Location Code"));

                if "Location Code" = '' then begin
                    if InvtSetup.Get then
                        "Inbound Whse. Handling Time" := InvtSetup."Inbound Whse. Handling Time";
                end else
                    if Location.Get("Location Code") then
                        "Inbound Whse. Handling Time" := Location."Inbound Whse. Handling Time";

                UpdateLeadTimeFields;
                UpdateDates;

                GetDefaultBin;
                CheckWMS;

                if "Document Type" = "Document Type"::"Return Order" then
                    ValidateReturnReasonCode(FieldNo("Location Code"));

                UpdateDirectUnitCostByField(FieldNo("Location Code"));
            end;
        }
        field(8; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            Editable = false;
            TableRelation = IF (Type = CONST(Item)) "Inventory Posting Group"
            ELSE
            IF (Type = CONST("Fixed Asset")) "FA Posting Group";
        }
        field(10; "Expected Receipt Date"; Date)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Expected Receipt Date';

            trigger OnValidate()
            var
                CustomCalendarChange: Array[2] of Record "Customized Calendar Change";
                IsHandled: Boolean;
            begin
                if not TrackingBlocked then begin
                    IsHandled := false;
                    OnValidateExpectedReceiptDateOnBeforeCheckDateConflict(Rec, IsHandled);
                    if not IsHandled then
                        CheckDateConflict.PurchLineCheck(Rec, CurrFieldNo <> 0);
                end;

                if "Expected Receipt Date" <> 0D then begin
                    CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
                    Validate(
                      "Planned Receipt Date",
                      CalendarMgmt.CalcDateBOC2(ReversedInternalLeadTimeDays("Expected Receipt Date"), "Expected Receipt Date", CustomCalendarChange, false))
                end else
                    Validate("Planned Receipt Date", "Expected Receipt Date");
            end;
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
            TableRelation = IF (Type = CONST("G/L Account"),
                                "System-Created Entry" = CONST(false)) "G/L Account".Name WHERE("Direct Posting" = CONST(true),
                                                                                               "Account Type" = CONST(Posting),
                                                                                               Blocked = CONST(false))
            ELSE
            IF (Type = CONST("G/L Account"),
                                                                                                        "System-Created Entry" = CONST(true)) "G/L Account".Name
            ELSE
            IF (Type = CONST(Item),
                                                                                                                 "Document Type" = FILTER(<> "Credit Memo" & <> "Return Order")) Item.Description WHERE(Blocked = CONST(false),
                                                                                                                                                                                                   "Purchasing Blocked" = CONST(false))
            ELSE
            IF (Type = CONST(Item),
                                                                                                                                                                                                            "Document Type" = FILTER("Credit Memo" | "Return Order")) Item.Description WHERE(Blocked = CONST(false))
            ELSE
            IF (Type = CONST("Fixed Asset")) "Fixed Asset".Description
            ELSE
            IF (Type = CONST("Charge (Item)")) "Item Charge".Description
            else
            if (Type = const(Resource)) Resource.Name;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                Item: Record Item;
                ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
                FindRecordMgt: Codeunit "Find Record Management";
                ReturnValue: Text[50];
                DescriptionIsNo: Boolean;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateDescription(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if Type = Type::" " then
                    exit;

                if "No." <> '' then
                    exit;

                case Type of
                    Type::Item:
                        begin
                            if IsReceivedFromOcr then
                                exit;

                            if StrLen(Description) <= MaxStrLen(Item."No.") then
                                DescriptionIsNo := Item.Get(Description)
                            else
                                DescriptionIsNo := false;

                            if not DescriptionIsNo then begin
                                Item.SetRange(Blocked, false);
                                if not IsCreditDocType() then
                                    Item.SetRange("Purchasing Blocked", false);

                                // looking for an item with exact description
                                Item.SetRange(Description, Description);
                                if Item.FindFirst() then begin
                                    CurrFieldNo := FieldNo("No.");
                                    Validate("No.", Item."No.");
                                    exit;
                                end;

                                // looking for an item with similar description
                                Item.SetFilter(Description, '''@' + ConvertStr(Description, '''', '?') + '''');
                                if Item.FindFirst then begin
                                    CurrFieldNo := FieldNo("No.");
                                    Validate("No.", Item."No.");
                                    exit;
                                end;
                            end;

                            if Item.TryGetItemNoOpenCard(ReturnValue, Description, false, false, false) then
                                case ReturnValue of
                                    '', "No.":
                                        Description := xRec.Description;
                                    else begin
                                            CurrFieldNo := FieldNo("No.");
                                            Validate("No.", CopyStr(ReturnValue, 1, MaxStrLen(Item."No.")));
                                        end;
                                end;
                        end;
                    else begin
                            ReturnValue := FindRecordMgt.FindNoByDescription(Type, Description, true);
                            if ReturnValue <> '' then begin
                                CurrFieldNo := FieldNo("No.");
                                Validate("No.", CopyStr(ReturnValue, 1, MaxStrLen("No.")));
                            end;
                        end;
                end;

                if ("No." = '') and GuiAllowed and ApplicationAreaMgmtFacade.IsFoundationEnabled then
                    if "Document Type" in ["Document Type"::Order] then
                        Error(CannotFindDescErr, Type, Description);
            end;
        }
        field(12; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(13; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                TestStatusOpen;
                IsHandled := false;
                OnValidateQuantityOnBeforeDropShptCheck(Rec, xRec, CurrFieldNo, IsHandled);
                if not IsHandled then
                    if "Drop Shipment" and ("Document Type" <> "Document Type"::Invoice) then
                        Error(
                          Text001, FieldCaption(Quantity), "Sales Order No.");

                "Quantity (Base)" :=
                    UOMMgt.CalcBaseQty("No.", "Variant Code", "Unit of Measure Code", Quantity, "Qty. per Unit of Measure");

                if IsCreditDocType then begin
                    if (Quantity * "Return Qty. Shipped" < 0) or
                       ((Abs(Quantity) < Abs("Return Qty. Shipped")) and ("Return Shipment No." = ''))
                    then
                        FieldError(Quantity, StrSubstNo(Text004, FieldCaption("Return Qty. Shipped")));
                    if ("Quantity (Base)" * "Return Qty. Shipped (Base)" < 0) or
                       ((Abs("Quantity (Base)") < Abs("Return Qty. Shipped (Base)")) and ("Return Shipment No." = ''))
                    then
                        FieldError("Quantity (Base)", StrSubstNo(Text004, FieldCaption("Return Qty. Shipped (Base)")));
                end else begin
                    if (Quantity * "Quantity Received" < 0) or
                       ((Abs(Quantity) < Abs("Quantity Received")) and ("Receipt No." = ''))
                    then
                        FieldError(Quantity, StrSubstNo(Text004, FieldCaption("Quantity Received")));
                    if ("Quantity (Base)" * "Qty. Received (Base)" < 0) or
                       ((Abs("Quantity (Base)") < Abs("Qty. Received (Base)")) and ("Receipt No." = ''))
                    then
                        FieldError("Quantity (Base)", StrSubstNo(Text004, FieldCaption("Qty. Received (Base)")));
                end;

                if (Type = Type::"Charge (Item)") and (CurrFieldNo <> 0) then begin
                    if (Quantity = 0) and ("Qty. to Assign" <> 0) then
                        FieldError("Qty. to Assign", StrSubstNo(Text011, FieldCaption(Quantity), Quantity));
                    if (Quantity * "Qty. Assigned" < 0) or (Abs(Quantity) < Abs("Qty. Assigned")) then
                        FieldError(Quantity, StrSubstNo(Text004, FieldCaption("Qty. Assigned")));
                end;

                if "Receipt No." <> '' then
                    CheckReceiptRelation
                else
                    if "Return Shipment No." <> '' then
                        CheckRetShptRelation;

                if (xRec.Quantity <> Quantity) or (xRec."Quantity (Base)" <> "Quantity (Base)") or
                   ("No." = xRec."No.")
                then begin
                    InitOutstanding;
                    if IsCreditDocType then
                        InitQtyToShip
                    else begin
                        IsHandled := FALSE;
                        OnValidateQuantityOnBeforeInitQtyToReceive(Rec, CurrFieldNo, IsHandled);
                        if not IsHandled then
                            InitQtyToReceive;
                    end;
                end;
                if (Quantity * xRec.Quantity < 0) or (Quantity = 0) then
                    InitItemAppl;

                if Type = Type::Item then begin
                    if Quantity <> xRec.Quantity then
                        PlanPriceCalcByField(FieldNo(Quantity));
                end else
                    Validate("Line Discount %");

                if Type = Type::"Charge (Item)" then
                    "Line Discount %" := 0;

                UpdateWithWarehouseReceive;
                if (xRec.Quantity <> Quantity) or (xRec."Quantity (Base)" <> "Quantity (Base)") then begin
                    OnBeforeVerifyReservedQty(Rec, xRec, FieldNo(Quantity));
                    ReservePurchLine.VerifyQuantity(Rec, xRec);
                    WhseValidateSourceLine.PurchaseLineVerifyChange(Rec, xRec);
                    CheckApplToItemLedgEntry;
                end;

                if (xRec.Quantity <> Quantity) and (Quantity = 0) and
                   ((Amount <> 0) or ("Amount Including VAT" <> 0) or ("VAT Base Amount" <> 0))
                then begin
                    Amount := 0;
                    "Amount Including VAT" := 0;
                    "VAT Base Amount" := 0;
                end;

                UpdatePrePaymentAmounts;

                if "Job Planning Line No." <> 0 then
                    Validate("Job Planning Line No.");

                if JobTaskIsSet then begin
                    CreateTempJobJnlLine(true);
                    UpdateJobPrices;
                end;

                CheckWMS;

                UpdateDirectUnitCostByField(FieldNo(Quantity))
            end;
        }
        field(16; "Outstanding Quantity"; Decimal)
        {
            Caption = 'Outstanding Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(17; "Qty. to Invoice"; Decimal)
        {
            Caption = 'Qty. to Invoice';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if "Qty. to Invoice" = MaxQtyToInvoice then
                    InitQtyToInvoice
                else
                    "Qty. to Invoice (Base)" :=
                        UOMMgt.CalcBaseQty("No.", "Variant Code", "Unit of Measure Code", "Qty. to Invoice", "Qty. per Unit of Measure");
                if ("Qty. to Invoice" * Quantity < 0) or (Abs("Qty. to Invoice") > Abs(MaxQtyToInvoice)) then
                    Error(
                      Text006,
                      MaxQtyToInvoice);
                if ("Qty. to Invoice (Base)" * "Quantity (Base)" < 0) or (Abs("Qty. to Invoice (Base)") > Abs(MaxQtyToInvoiceBase)) then
                    Error(
                      Text007,
                      MaxQtyToInvoiceBase);
                "VAT Difference" := 0;
                CalcInvDiscToInvoice;
                CalcPrepaymentToDeduct;

                if "Job Planning Line No." <> 0 then
                    Validate("Job Planning Line No.");
            end;
        }
        field(18; "Qty. to Receive"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Qty. to Receive';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                GetLocation("Location Code");
                if (CurrFieldNo <> 0) and (Type = Type::Item) and (not "Drop Shipment") then begin
                    if Location."Require Receive" and ("Qty. to Receive" <> 0) then
                        CheckWarehouse;
                    WhseValidateSourceLine.PurchaseLineVerifyChange(Rec, xRec);
                end;
                OnValidateQtyToReceiveOnAfterCheck(Rec, CurrFieldNo);

                if "Qty. to Receive" = Quantity - "Quantity Received" then begin
                    IsHandled := false;
                    OnValidateQtyToReceiveOnBeforeInitQtyToReceive(Rec, CurrFieldNo, IsHandled);
                    if not IsHandled then
                        InitQtyToReceive;
                end else begin
                    "Qty. to Receive (Base)" :=
                        UOMMgt.CalcBaseQty("No.", "Variant Code", "Unit of Measure Code", "Qty. to Receive", "Qty. per Unit of Measure");
                    InitQtyToInvoice;
                end;

                IsHandled := false;
                OnValidateQtyToReceiveOnAfterInitQty(Rec, xRec, CurrFieldNo, IsHandled);
                if not OverReceiptProcessing() then
                    if not IsHandled then begin
                        if ((("Qty. to Receive" < 0) xor (Quantity < 0)) and (Quantity <> 0) and ("Qty. to Receive" <> 0)) or
                           (Abs("Qty. to Receive") > Abs("Outstanding Quantity")) or
                           (((Quantity < 0) xor ("Outstanding Quantity" < 0)) and (Quantity <> 0) and ("Outstanding Quantity" <> 0))
                        then
                            Error(Text008, "Outstanding Quantity");
                        if ((("Qty. to Receive (Base)" < 0) xor ("Quantity (Base)" < 0)) and ("Quantity (Base)" <> 0) and ("Qty. to Receive (Base)" <> 0)) or
                           (Abs("Qty. to Receive (Base)") > Abs("Outstanding Qty. (Base)")) or
                           ((("Quantity (Base)" < 0) xor ("Outstanding Qty. (Base)" < 0)) and ("Quantity (Base)" <> 0) and ("Outstanding Qty. (Base)" <> 0))
                        then
                            Error(Text009, "Outstanding Qty. (Base)");
                    end;

                if (CurrFieldNo <> 0) and (Type = Type::Item) and ("Qty. to Receive" < 0) then
                    CheckApplToItemLedgEntry;

                if "Job Planning Line No." <> 0 then
                    Validate("Job Planning Line No.");
            end;
        }
        field(22; "Direct Unit Cost"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            CaptionClass = GetCaptionClass(FieldNo("Direct Unit Cost"));
            Caption = 'Direct Unit Cost';

            trigger OnValidate()
            begin
                Validate("Line Discount %");
            end;
        }
        field(23; "Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (LCY)';

            trigger OnValidate()
            var
                Item: Record Item;
                IndirectCostPercent: Decimal;
            begin
                TestStatusOpen;
                TestField("No.");
                TestField(Quantity);

                if "Prod. Order No." <> '' then
                    Error(
                      Text99000000,
                      FieldCaption("Unit Cost (LCY)"));

                if CurrFieldNo = FieldNo("Unit Cost (LCY)") then
                    if Type = Type::Item then begin
                        GetItem(Item);
                        if Item."Costing Method" = Item."Costing Method"::Standard then
                            Error(
                              Text010,
                              FieldCaption("Unit Cost (LCY)"), Item.FieldCaption("Costing Method"), Item."Costing Method");
                    end;

                UnitCostCurrency := "Unit Cost (LCY)";
                GetPurchHeader;
                if PurchHeader."Currency Code" <> '' then begin
                    PurchHeader.TestField("Currency Factor");
                    GetGLSetup;
                    UnitCostCurrency :=
                      Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                          GetDate, "Currency Code",
                          "Unit Cost (LCY)", PurchHeader."Currency Factor"),
                        GLSetup."Unit-Amount Rounding Precision");
                end;

                OnValidateUnitCostLCYOnAfterUpdateUnitCostCurrency(Rec, UnitCostCurrency);

                "Indirect Cost %" := 0;
                if ("Direct Unit Cost" <> 0) and
                   ("Direct Unit Cost" <> ("Line Discount Amount" / Quantity))
                then begin
                    IndirectCostPercent :=
                      Round(
                        (UnitCostCurrency - "Direct Unit Cost" + "Line Discount Amount" / Quantity) /
                        ("Direct Unit Cost" - "Line Discount Amount" / Quantity) * 100, 0.00001);
                    if IndirectCostPercent >= 0 then
                        "Indirect Cost %" := IndirectCostPercent;
                end;

                UpdateSalesCost;

                if JobTaskIsSet then begin
                    CreateTempJobJnlLine(false);
                    TempJobJnlLine.Validate("Unit Cost (LCY)", "Unit Cost (LCY)");
                    UpdateJobPrices;
                end
            end;
        }
        field(25; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(27; "Line Discount %"; Decimal)
        {
            Caption = 'Line Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateLineDiscountPercent(true);
                NotifyOnMissingSetup(FieldNo("Line Discount Amount"));
            end;
        }
        field(28; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';

            trigger OnValidate()
            begin
                GetPurchHeader;
                "Line Discount Amount" := Round("Line Discount Amount", Currency."Amount Rounding Precision");
                TestStatusOpen;
                TestField(Quantity);
                if xRec."Line Discount Amount" <> "Line Discount Amount" then
                    UpdateLineDiscPct;
                "Inv. Discount Amount" := 0;
                "Inv. Disc. Amount to Invoice" := 0;
                UpdateAmounts;
                UpdateUnitCost;
                NotifyOnMissingSetup(FieldNo("Line Discount Amount"));
            end;
        }
        field(29; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            Editable = false;

            trigger OnValidate()
            begin
                GetPurchHeader;
                Amount := Round(Amount, Currency."Amount Rounding Precision");
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            "VAT Base Amount" :=
                              Round(Amount * (1 - PurchHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
                            "Amount Including VAT" :=
                              Round(Amount + "VAT Base Amount" * "VAT %" / 100, Currency."Amount Rounding Precision");
                        end;
                    "VAT Calculation Type"::"Full VAT":
                        if Amount <> 0 then
                            FieldError(Amount,
                              StrSubstNo(
                                Text011, FieldCaption("VAT Calculation Type"),
                                "VAT Calculation Type"));
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            PurchHeader.TestField("VAT Base Discount %", 0);
                            "VAT Base Amount" := Amount;
                            if "Use Tax" then
                                "Amount Including VAT" := "VAT Base Amount"
                            else begin
                                "Amount Including VAT" :=
                                  Amount +
                                  Round(
                                    SalesTaxCalculate.CalculateTax(
                                      "Tax Area Code", "Tax Group Code", "Tax Liable", PurchHeader."Posting Date",
                                      "VAT Base Amount", "Quantity (Base)", PurchHeader."Currency Factor"),
                                    Currency."Amount Rounding Precision");
                                OnAfterSalesTaxCalculate(Rec, PurchHeader, Currency);
                                if "VAT Base Amount" <> 0 then
                                    "VAT %" :=
                                      Round(100 * ("Amount Including VAT" - "VAT Base Amount") / "VAT Base Amount", 0.00001)
                                else
                                    "VAT %" := 0;
                            end;
                        end;
                end;

                InitOutstandingAmount;
                UpdateUnitCost;
            end;
        }
        field(30; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
            Editable = false;

            trigger OnValidate()
            begin
                GetPurchHeader;
                "Amount Including VAT" := Round("Amount Including VAT", Currency."Amount Rounding Precision");
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            Amount :=
                              Round(
                                "Amount Including VAT" /
                                (1 + (1 - PurchHeader."VAT Base Discount %" / 100) * "VAT %" / 100),
                                Currency."Amount Rounding Precision");
                            "VAT Base Amount" :=
                              Round(Amount * (1 - PurchHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
                        end;
                    "VAT Calculation Type"::"Full VAT":
                        begin
                            Amount := 0;
                            "VAT Base Amount" := 0;
                        end;
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            PurchHeader.TestField("VAT Base Discount %", 0);
                            if "Use Tax" then begin
                                Amount := "Amount Including VAT";
                                "VAT Base Amount" := Amount;
                            end else begin
                                Amount :=
                                  Round(
                                    SalesTaxCalculate.ReverseCalculateTax(
                                      "Tax Area Code", "Tax Group Code", "Tax Liable", PurchHeader."Posting Date",
                                      "Amount Including VAT", "Quantity (Base)", PurchHeader."Currency Factor"),
                                    Currency."Amount Rounding Precision");
                                OnAfterSalesTaxCalculateReverse(Rec, PurchHeader, Currency);
                                "VAT Base Amount" := Amount;
                                if "VAT Base Amount" <> 0 then
                                    "VAT %" :=
                                      Round(100 * ("Amount Including VAT" - "VAT Base Amount") / "VAT Base Amount", 0.00001)
                                else
                                    "VAT %" := 0;
                            end;
                        end;
                end;

                InitOutstandingAmount;
                UpdateUnitCost;
            end;
        }
        field(31; "Unit Price (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Price (LCY)';
        }
        field(32; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            InitValue = true;

            trigger OnValidate()
            begin
                TestStatusOpen;
                if ("VAT Calculation Type" = "VAT Calculation Type"::"Full VAT") and "Allow Invoice Disc." then
                    Error(CannotAllowInvDiscountErr, FieldCaption("Allow Invoice Disc."));

                if "Allow Invoice Disc." <> xRec."Allow Invoice Disc." then begin
                    if not "Allow Invoice Disc." then begin
                        "Inv. Discount Amount" := 0;
                        "Inv. Disc. Amount to Invoice" := 0;
                    end;
                    UpdateAmounts;
                    UpdateUnitCost;
                end;
            end;
        }
        field(34; "Gross Weight"; Decimal)
        {
            Caption = 'Gross Weight';
            DecimalPlaces = 0 : 5;
        }
        field(35; "Net Weight"; Decimal)
        {
            Caption = 'Net Weight';
            DecimalPlaces = 0 : 5;
        }
        field(36; "Units per Parcel"; Decimal)
        {
            Caption = 'Units per Parcel';
            DecimalPlaces = 0 : 5;
        }
        field(37; "Unit Volume"; Decimal)
        {
            Caption = 'Unit Volume';
            DecimalPlaces = 0 : 5;
        }
        field(38; "Appl.-to Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-to Item Entry';

            trigger OnLookup()
            begin
                SelectItemEntry;
            end;

            trigger OnValidate()
            begin
                if "Appl.-to Item Entry" <> 0 then
                    "Location Code" := CheckApplToItemLedgEntry;
            end;
        }
        field(40; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1),
                                                          Blocked = CONST(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(41; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2),
                                                          Blocked = CONST(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(45; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            TableRelation = Job;

            trigger OnValidate()
            var
                Job: Record Job;
            begin
                TestField("Drop Shipment", false);
                TestField("Special Order", false);
                TestField("Receipt No.", '');
                if "Document Type" = "Document Type"::Order then
                    TestField("Quantity Received", 0);

                if CheckReservationForJobNo then
                    TestField("Job No.", '');

                if "Job No." <> xRec."Job No." then begin
                    Validate("Job Task No.", '');
                    Validate("Job Planning Line No.", 0);
                end;

                if "Job No." = '' then begin
                    CreateDim(
                      DATABASE::Job, "Job No.",
                      DimMgt.TypeToTableID3(Type), "No.",
                      DATABASE::"Responsibility Center", "Responsibility Center",
                      DATABASE::"Work Center", "Work Center No.");
                    exit;
                end;

                if not (Type in [Type::Item, Type::"G/L Account"]) then
                    FieldError("Job No.", StrSubstNo(Text012, FieldCaption(Type), Type));
                Job.Get("Job No.");
                Job.TestBlocked;
                "Job Currency Code" := Job."Currency Code";

                CreateDim(
                  DATABASE::Job, "Job No.",
                  DimMgt.TypeToTableID3(Type), "No.",
                  DATABASE::"Responsibility Center", "Responsibility Center",
                  DATABASE::"Work Center", "Work Center No.");
            end;
        }
        field(54; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                TestField("No.");
                TestStatusOpen;

                if Type = Type::"Charge (Item)" then
                    TestField("Indirect Cost %", 0);

                if (Type = Type::Item) and ("Prod. Order No." = '') then begin
                    GetItem(Item);
                    Item.TestField(Type, Item.Type::Inventory);
                    if Item."Costing Method" = Item."Costing Method"::Standard then
                        Error(
                          Text010,
                          FieldCaption("Indirect Cost %"), Item.FieldCaption("Costing Method"), Item."Costing Method");
                end;

                UpdateUnitCost;
            end;
        }
        field(56; "Recalculate Invoice Disc."; Boolean)
        {
            Caption = 'Recalculate Invoice Disc.';
            Editable = false;
        }
        field(57; "Outstanding Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Outstanding Amount';
            Editable = false;

            trigger OnValidate()
            var
                Currency2: Record Currency;
            begin
                GetPurchHeader;
                Currency2.InitRoundingPrecision;
                if PurchHeader."Currency Code" <> '' then
                    "Outstanding Amount (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          GetDate, "Currency Code",
                          "Outstanding Amount", PurchHeader."Currency Factor"),
                        Currency2."Amount Rounding Precision")
                else
                    "Outstanding Amount (LCY)" :=
                      Round("Outstanding Amount", Currency2."Amount Rounding Precision");

                "Outstanding Amt. Ex. VAT (LCY)" :=
                  Round("Outstanding Amount (LCY)" / (1 + "VAT %" / 100), Currency2."Amount Rounding Precision");
            end;
        }
        field(58; "Qty. Rcd. Not Invoiced"; Decimal)
        {
            Caption = 'Qty. Rcd. Not Invoiced';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(59; "Amt. Rcd. Not Invoiced"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amt. Rcd. Not Invoiced';
            Editable = false;

            trigger OnValidate()
            var
                Currency2: Record Currency;
            begin
                GetPurchHeader;
                Currency2.InitRoundingPrecision;
                if PurchHeader."Currency Code" <> '' then
                    "Amt. Rcd. Not Invoiced (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          GetDate, "Currency Code",
                          "Amt. Rcd. Not Invoiced", PurchHeader."Currency Factor"),
                        Currency2."Amount Rounding Precision")
                else
                    "Amt. Rcd. Not Invoiced (LCY)" :=
                      Round("Amt. Rcd. Not Invoiced", Currency2."Amount Rounding Precision");

                "A. Rcd. Not Inv. Ex. VAT (LCY)" :=
                  Round("Amt. Rcd. Not Invoiced (LCY)" / (1 + "VAT %" / 100), Currency2."Amount Rounding Precision");
            end;
        }
        field(60; "Quantity Received"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Quantity Received';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(61; "Quantity Invoiced"; Decimal)
        {
            Caption = 'Quantity Invoiced';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(63; "Receipt No."; Code[20])
        {
            Caption = 'Receipt No.';
            Editable = false;
        }
        field(64; "Receipt Line No."; Integer)
        {
            Caption = 'Receipt Line No.';
            Editable = false;
        }
        field(65; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(66; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
        }
        field(67; "Profit %"; Decimal)
        {
            Caption = 'Profit %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(68; "Pay-to Vendor No."; Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            Editable = false;
            TableRelation = Vendor;
        }
        field(69; "Inv. Discount Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Discount Amount';
            Editable = false;

            trigger OnValidate()
            begin
                UpdateAmounts;
                UpdateUnitCost;
                CalcInvDiscToInvoice;
            end;
        }
        field(70; "Vendor Item No."; Text[50])
        {
            Caption = 'Vendor Item No.';

            trigger OnValidate()
            begin
                if PurchHeader."Send IC Document" and
                   ("IC Partner Ref. Type" = "IC Partner Ref. Type"::"Vendor Item No.")
                then
                    "IC Partner Reference" := "Vendor Item No.";
            end;
        }
        field(71; "Sales Order No."; Code[20])
        {
            Caption = 'Sales Order No.';
            Editable = false;
            TableRelation = IF ("Drop Shipment" = CONST(true)) "Sales Header"."No." WHERE("Document Type" = CONST(Order));

            trigger OnValidate()
            begin
                if (xRec."Sales Order No." <> "Sales Order No.") and (Quantity <> 0) then begin
                    ReservePurchLine.VerifyChange(Rec, xRec);
                    WhseValidateSourceLine.PurchaseLineVerifyChange(Rec, xRec);
                end;
            end;
        }
        field(72; "Sales Order Line No."; Integer)
        {
            Caption = 'Sales Order Line No.';
            Editable = false;
            TableRelation = IF ("Drop Shipment" = CONST(true)) "Sales Line"."Line No." WHERE("Document Type" = CONST(Order),
                                                                                            "Document No." = FIELD("Sales Order No."));

            trigger OnValidate()
            begin
                if (xRec."Sales Order Line No." <> "Sales Order Line No.") and (Quantity <> 0) then begin
                    ReservePurchLine.VerifyChange(Rec, xRec);
                    WhseValidateSourceLine.PurchaseLineVerifyChange(Rec, xRec);
                end;
            end;
        }
        field(73; "Drop Shipment"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Drop Shipment';
            Editable = false;

            trigger OnValidate()
            begin
                if (xRec."Drop Shipment" <> "Drop Shipment") and (Quantity <> 0) then begin
                    ReservePurchLine.VerifyChange(Rec, xRec);
                    WhseValidateSourceLine.PurchaseLineVerifyChange(Rec, xRec);
                end;
                if "Drop Shipment" then begin
                    "Bin Code" := '';
                    Evaluate("Inbound Whse. Handling Time", '<0D>');
                    Validate("Inbound Whse. Handling Time");
                    InitOutstanding;
                    InitQtyToReceive;
                end;
            end;
        }
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            begin
                if xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Gen. Bus. Posting Group") then
                        Validate("VAT Bus. Posting Group", GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
        }
        field(75; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                TestStatusOpen;
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then
                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
        }
        field(77; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        field(78; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(79; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(80; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            Editable = false;
            TableRelation = "Purchase Line"."Line No." WHERE("Document Type" = FIELD("Document Type"),
                                                              "Document No." = FIELD("Document No."));
        }
        field(81; "Entry Point"; Code[10])
        {
            Caption = 'Entry Point';
            TableRelation = "Entry/Exit Point";
        }
        field(82; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(83; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(85; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                UpdateAmounts;
            end;
        }
        field(86; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';

            trigger OnValidate()
            begin
                UpdateAmounts;
            end;
        }
        field(87; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                TestStatusOpen;
                UpdateAmounts;
            end;
        }
        field(88; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';

            trigger OnValidate()
            begin
                UpdateAmounts;
            end;
        }
        field(89; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        field(90; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                TestStatusOpen;
                VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                OnValidateVATProdPostingGroupOnAfterVATPostingSetupGet(VATPostingSetup);
                "VAT Difference" := 0;
                GetPurchHeader;
                "VAT %" := VATPostingSetup."VAT %";
                "VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
                if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then
                    Validate("Allow Invoice Disc.", false);
                "VAT Identifier" := VATPostingSetup."VAT Identifier";

                IsHandled := false;
                OnValidateVATProdPostingGroupOnBeforeCheckVATCalcType(Rec, VATPostingSetup, IsHandled);
                if not IsHandled then
                    case "VAT Calculation Type" of
                        "VAT Calculation Type"::"Reverse Charge VAT",
                      "VAT Calculation Type"::"Sales Tax":
                            "VAT %" := 0;
                        "VAT Calculation Type"::"Full VAT":
                            begin
                                TestField(Type, Type::"G/L Account");
                                TestField("No.", VATPostingSetup.GetPurchAccount(false));
                            end;
                    end;

                if PurchHeader."Prices Including VAT" and (Type in [Type::Item, Type::Resource]) then
                    "Direct Unit Cost" :=
                      Round(
                        "Direct Unit Cost" * (100 + "VAT %") / (100 + xRec."VAT %"),
                        Currency."Unit-Amount Rounding Precision");
                UpdateAmounts;
            end;
        }
        field(91; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(92; "Outstanding Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Outstanding Amount (LCY)';
            Editable = false;
        }
        field(93; "Amt. Rcd. Not Invoiced (LCY)"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            AutoFormatType = 1;
            Caption = 'Amt. Rcd. Not Invoiced (LCY)';
            Editable = false;
        }
        field(95; "Reserved Quantity"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = Sum ("Reservation Entry".Quantity WHERE("Source ID" = FIELD("Document No."),
                                                                  "Source Ref. No." = FIELD("Line No."),
                                                                  "Source Type" = CONST(39),
                                                                  "Source Subtype" = FIELD("Document Type"),
                                                                  "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(97; "Blanket Order No."; Code[20])
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Blanket Order No.';
            TableRelation = "Purchase Header"."No." WHERE("Document Type" = CONST("Blanket Order"));
            //This property is currently not supported
            //TestTableRelation = false;

            trigger OnLookup()
            begin
                TestField("Quantity Received", 0);
                BlanketOrderLookup;
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                TestField("Quantity Received", 0);

                IsHandled := false;
                OnValidateBlanketOrderNoOnAfterCheck(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Blanket Order No." = '' then
                    "Blanket Order Line No." := 0
                else
                    Validate("Blanket Order Line No.");
            end;
        }
        field(98; "Blanket Order Line No."; Integer)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Blanket Order Line No.';
            TableRelation = "Purchase Line"."Line No." WHERE("Document Type" = CONST("Blanket Order"),
                                                              "Document No." = FIELD("Blanket Order No."));
            //This property is currently not supported
            //TestTableRelation = false;

            trigger OnLookup()
            begin
                BlanketOrderLookup;
            end;

            trigger OnValidate()
            begin
                TestField("Quantity Received", 0);
                if "Blanket Order Line No." <> 0 then begin
                    PurchLine2.Get("Document Type"::"Blanket Order", "Blanket Order No.", "Blanket Order Line No.");
                    PurchLine2.TestField(Type, Type);
                    PurchLine2.TestField("No.", "No.");
                    PurchLine2.TestField("Pay-to Vendor No.", "Pay-to Vendor No.");
                    PurchLine2.TestField("Buy-from Vendor No.", "Buy-from Vendor No.");
                    if "Drop Shipment" then begin
                        PurchLine2.TestField("Variant Code", "Variant Code");
                        PurchLine2.TestField("Location Code", "Location Code");
                        PurchLine2.TestField("Unit of Measure Code", "Unit of Measure Code");
                    end else begin
                        Validate("Variant Code", PurchLine2."Variant Code");
                        Validate("Location Code", PurchLine2."Location Code");
                        Validate("Unit of Measure Code", PurchLine2."Unit of Measure Code");
                    end;
                    Validate("Direct Unit Cost", PurchLine2."Direct Unit Cost");
                    Validate("Line Discount %", PurchLine2."Line Discount %");
                end;
            end;
        }
        field(99; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            Editable = false;
        }
        field(100; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            Editable = false;
        }
        field(101; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
        field(103; "Line Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Line Amount"));
            Caption = 'Line Amount';

            trigger OnValidate()
            begin
                TestField(Type);
                TestField(Quantity);
                TestField("Direct Unit Cost");

                GetPurchHeader;
                "Line Amount" := Round("Line Amount", Currency."Amount Rounding Precision");
                Validate(
                  "Line Discount Amount", Round(Quantity * "Direct Unit Cost", Currency."Amount Rounding Precision") - "Line Amount");
            end;
        }
        field(104; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
        }
        field(105; "Inv. Disc. Amount to Invoice"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Disc. Amount to Invoice';
            Editable = false;
        }
        field(106; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            Editable = false;
        }
        field(107; "IC Partner Ref. Type"; Enum "IC Partner Reference Type")
        {
            AccessByPermission = TableData "IC G/L Account" = R;
            Caption = 'IC Partner Ref. Type';

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                if "IC Partner Code" <> '' then
                    "IC Partner Ref. Type" := "IC Partner Ref. Type"::"G/L Account";
                if "IC Partner Ref. Type" <> xRec."IC Partner Ref. Type" then
                    "IC Partner Reference" := '';
                if "IC Partner Ref. Type" = "IC Partner Ref. Type"::"Common Item No." then begin
                    GetItem(Item);
                    Item.TestField("Common Item No.");
                    "IC Partner Reference" := Item."Common Item No.";
                end;
            end;
        }
        field(108; "IC Partner Reference"; Code[20])
        {
            AccessByPermission = TableData "IC G/L Account" = R;
            Caption = 'IC Partner Reference';

            trigger OnLookup()
            var
                ICGLAccount: Record "IC G/L Account";
                Item: Record Item;
                ItemCrossReference: Record "Item Cross Reference";
                ItemVendorCatalog: Record "Item Vendor";
            begin
                if "No." <> '' then
                    case "IC Partner Ref. Type" of
                        "IC Partner Ref. Type"::"G/L Account":
                            begin
                                if ICGLAccount.Get("IC Partner Reference") then;
                                if PAGE.RunModal(PAGE::"IC G/L Account List", ICGLAccount) = ACTION::LookupOK then
                                    Validate("IC Partner Reference", ICGLAccount."No.");
                            end;
                        "IC Partner Ref. Type"::Item:
                            begin
                                if Item.Get("IC Partner Reference") then;
                                if PAGE.RunModal(PAGE::"Item List", Item) = ACTION::LookupOK then
                                    Validate("IC Partner Reference", Item."No.");
                            end;
                        "IC Partner Ref. Type"::"Cross Reference":
                            begin
                                GetPurchHeader;
                                ItemCrossReference.Reset();
                                ItemCrossReference.SetCurrentKey("Cross-Reference Type", "Cross-Reference Type No.");
                                ItemCrossReference.SetFilter(
                                  "Cross-Reference Type", '%1|%2',
                                  ItemCrossReference."Cross-Reference Type"::Vendor,
                                  ItemCrossReference."Cross-Reference Type"::" ");
                                ItemCrossReference.SetFilter("Cross-Reference Type No.", '%1|%2', PurchHeader."Buy-from Vendor No.", '');
                                if PAGE.RunModal(PAGE::"Cross Reference List", ItemCrossReference) = ACTION::LookupOK then
                                    Validate("IC Partner Reference", ItemCrossReference."Cross-Reference No.");
                            end;
                        "IC Partner Ref. Type"::"Vendor Item No.":
                            begin
                                GetPurchHeader;
                                ItemVendorCatalog.SetCurrentKey("Vendor No.");
                                ItemVendorCatalog.SetRange("Vendor No.", PurchHeader."Buy-from Vendor No.");
                                if PAGE.RunModal(PAGE::"Vendor Item Catalog", ItemVendorCatalog) = ACTION::LookupOK then
                                    Validate("IC Partner Reference", ItemVendorCatalog."Vendor Item No.");
                            end;
                    end;
            end;
        }
        field(109; "Prepayment %"; Decimal)
        {
            Caption = 'Prepayment %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusOpen;
                UpdatePrepmtSetupFields;

                if HasTypeToFillMandatoryFields then
                    UpdateAmounts;
                UpdateBaseAmounts(Amount, "Amount Including VAT", "VAT Base Amount");
            end;
        }
        field(110; "Prepmt. Line Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Prepmt. Line Amount"));
            Caption = 'Prepmt. Line Amount';
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusOpen;
                PrePaymentLineAmountEntered := true;
                TestField("Line Amount");
                if "Prepmt. Line Amount" < "Prepmt. Amt. Inv." then
                    FieldError("Prepmt. Line Amount", StrSubstNo(Text038, "Prepmt. Amt. Inv."));
                if "Prepmt. Line Amount" > "Line Amount" then
                    FieldError("Prepmt. Line Amount", StrSubstNo(Text039, "Line Amount"));
                Validate("Prepayment %", Round("Prepmt. Line Amount" * 100 / "Line Amount", 0.00001));
            end;
        }
        field(111; "Prepmt. Amt. Inv."; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Prepmt. Amt. Inv."));
            Caption = 'Prepmt. Amt. Inv.';
            Editable = false;
        }
        field(112; "Prepmt. Amt. Incl. VAT"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt. Amt. Incl. VAT';
            Editable = false;
        }
        field(113; "Prepayment Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepayment Amount';
            Editable = false;
        }
        field(114; "Prepmt. VAT Base Amt."; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt. VAT Base Amt.';
            Editable = false;
        }
        field(115; "Prepayment VAT %"; Decimal)
        {
            Caption = 'Prepayment VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;
        }
        field(116; "Prepmt. VAT Calc. Type"; Enum "Tax Calculation Type")
        {
            Caption = 'Prepmt. VAT Calc. Type';
            Editable = false;
        }
        field(117; "Prepayment VAT Identifier"; Code[20])
        {
            Caption = 'Prepayment VAT Identifier';
            Editable = false;
        }
        field(118; "Prepayment Tax Area Code"; Code[20])
        {
            Caption = 'Prepayment Tax Area Code';
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                UpdateAmounts;
            end;
        }
        field(119; "Prepayment Tax Liable"; Boolean)
        {
            Caption = 'Prepayment Tax Liable';

            trigger OnValidate()
            begin
                UpdateAmounts;
            end;
        }
        field(120; "Prepayment Tax Group Code"; Code[20])
        {
            Caption = 'Prepayment Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                TestStatusOpen;
                UpdateAmounts;
            end;
        }
        field(121; "Prepmt Amt to Deduct"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Prepmt Amt to Deduct"));
            Caption = 'Prepmt Amt to Deduct';
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Prepmt Amt to Deduct" > "Prepmt. Amt. Inv." - "Prepmt Amt Deducted" then
                    FieldError(
                      "Prepmt Amt to Deduct",
                      StrSubstNo(Text039, "Prepmt. Amt. Inv." - "Prepmt Amt Deducted"));

                if "Prepmt Amt to Deduct" > "Qty. to Invoice" * "Direct Unit Cost" then
                    FieldError(
                      "Prepmt Amt to Deduct",
                      StrSubstNo(Text039, "Qty. to Invoice" * "Direct Unit Cost"));
                if ("Prepmt. Amt. Inv." - "Prepmt Amt to Deduct" - "Prepmt Amt Deducted") >
                   (Quantity - "Qty. to Invoice" - "Quantity Invoiced") * "Direct Unit Cost"
                then
                    FieldError(
                      "Prepmt Amt to Deduct",
                      StrSubstNo(Text038,
                        "Prepmt. Amt. Inv." - "Prepmt Amt Deducted" -
                        (Quantity - "Qty. to Invoice" - "Quantity Invoiced") * "Direct Unit Cost"));
            end;
        }
        field(122; "Prepmt Amt Deducted"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Prepmt Amt Deducted"));
            Caption = 'Prepmt Amt Deducted';
            Editable = false;
        }
        field(123; "Prepayment Line"; Boolean)
        {
            Caption = 'Prepayment Line';
            Editable = false;
        }
        field(124; "Prepmt. Amount Inv. Incl. VAT"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt. Amount Inv. Incl. VAT';
            Editable = false;
        }
        field(129; "Prepmt. Amount Inv. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Prepmt. Amount Inv. (LCY)';
            Editable = false;
        }
        field(130; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            TableRelation = "IC Partner";

            trigger OnValidate()
            begin
                if "IC Partner Code" <> '' then begin
                    TestField(Type, Type::"G/L Account");
                    GetPurchHeader;
                    PurchHeader.TestField("Buy-from IC Partner Code", '');
                    PurchHeader.TestField("Pay-to IC Partner Code", '');
                    Validate("IC Partner Ref. Type", "IC Partner Ref. Type"::"G/L Account");
                end;
            end;
        }
        field(132; "Prepmt. VAT Amount Inv. (LCY)"; Decimal)
        {
            Caption = 'Prepmt. VAT Amount Inv. (LCY)';
            Editable = false;
        }
        field(135; "Prepayment VAT Difference"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepayment VAT Difference';
            Editable = false;
        }
        field(136; "Prepmt VAT Diff. to Deduct"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt VAT Diff. to Deduct';
            Editable = false;
        }
        field(137; "Prepmt VAT Diff. Deducted"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt VAT Diff. Deducted';
            Editable = false;
        }
        field(140; "Outstanding Amt. Ex. VAT (LCY)"; Decimal)
        {
            Caption = 'Outstanding Amt. Ex. VAT (LCY)';
        }
        field(141; "A. Rcd. Not Inv. Ex. VAT (LCY)"; Decimal)
        {
            Caption = 'A. Rcd. Not Inv. Ex. VAT (LCY)';
        }
        field(145; "Pmt. Discount Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Pmt. Discount Amount';

            trigger OnValidate()
            begin
                TestField(Quantity);
                UpdateAmounts;
            end;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions;
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(1001; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            TableRelation = "Job Task"."Job Task No." WHERE("Job No." = FIELD("Job No."));

            trigger OnValidate()
            begin
                TestField("Receipt No.", '');

                if "Job Task No." <> xRec."Job Task No." then begin
                    Validate("Job Planning Line No.", 0);
                    if "Document Type" = "Document Type"::Order then
                        TestField("Quantity Received", 0);
                end;

                if "Job Task No." = '' then begin
                    Clear(TempJobJnlLine);
                    "Job Line Type" := "Job Line Type"::" ";
                    UpdateJobPrices;
                    CreateDim(
                      DimMgt.TypeToTableID3(Type), "No.",
                      DATABASE::Job, "Job No.",
                      DATABASE::"Responsibility Center", "Responsibility Center",
                      DATABASE::"Work Center", "Work Center No.");
                    exit;
                end;

                JobSetCurrencyFactor;
                if JobTaskIsSet then begin
                    CreateTempJobJnlLine(true);
                    UpdateJobPrices;
                end;
                UpdateDimensionsFromJobTask;
            end;
        }
        field(1002; "Job Line Type"; Option)
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Job Line Type';
            OptionCaption = ' ,Budget,Billable,Both Budget and Billable';
            OptionMembers = " ",Budget,Billable,"Both Budget and Billable";

            trigger OnValidate()
            begin
                TestField("Receipt No.", '');
                if "Document Type" = "Document Type"::Order then
                    TestField("Quantity Received", 0);

                if "Job Planning Line No." <> 0 then
                    Error(Text048, FieldCaption("Job Line Type"), FieldCaption("Job Planning Line No."));
            end;
        }
        field(1003; "Job Unit Price"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            BlankZero = true;
            Caption = 'Job Unit Price';

            trigger OnValidate()
            begin
                TestField("Receipt No.", '');
                if "Document Type" = "Document Type"::Order then
                    TestField("Quantity Received", 0);

                if JobTaskIsSet then begin
                    CreateTempJobJnlLine(false);
                    TempJobJnlLine.Validate("Unit Price", "Job Unit Price");
                    UpdateJobPrices;
                end;
            end;
        }
        field(1004; "Job Total Price"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            BlankZero = true;
            Caption = 'Job Total Price';
            Editable = false;
        }
        field(1005; "Job Line Amount"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Job Line Amount';

            trigger OnValidate()
            begin
                TestField("Receipt No.", '');
                if "Document Type" = "Document Type"::Order then
                    TestField("Quantity Received", 0);

                if JobTaskIsSet then begin
                    CreateTempJobJnlLine(false);
                    TempJobJnlLine.Validate("Line Amount", "Job Line Amount");
                    UpdateJobPrices;
                end;
            end;
        }
        field(1006; "Job Line Discount Amount"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Job Line Discount Amount';

            trigger OnValidate()
            begin
                TestField("Receipt No.", '');
                if "Document Type" = "Document Type"::Order then
                    TestField("Quantity Received", 0);

                if JobTaskIsSet then begin
                    CreateTempJobJnlLine(false);
                    TempJobJnlLine.Validate("Line Discount Amount", "Job Line Discount Amount");
                    UpdateJobPrices;
                end;
            end;
        }
        field(1007; "Job Line Discount %"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            BlankZero = true;
            Caption = 'Job Line Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestField("Receipt No.", '');
                if "Document Type" = "Document Type"::Order then
                    TestField("Quantity Received", 0);

                if JobTaskIsSet then begin
                    CreateTempJobJnlLine(false);
                    TempJobJnlLine.Validate("Line Discount %", "Job Line Discount %");
                    UpdateJobPrices;
                end;
            end;
        }
        field(1008; "Job Unit Price (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            BlankZero = true;
            Caption = 'Job Unit Price (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                TestField("Receipt No.", '');
                if "Document Type" = "Document Type"::Order then
                    TestField("Quantity Received", 0);

                if JobTaskIsSet then begin
                    CreateTempJobJnlLine(false);
                    TempJobJnlLine.Validate("Unit Price (LCY)", "Job Unit Price (LCY)");
                    UpdateJobPrices;
                end;
            end;
        }
        field(1009; "Job Total Price (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            BlankZero = true;
            Caption = 'Job Total Price (LCY)';
            Editable = false;
        }
        field(1010; "Job Line Amount (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Job Line Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                TestField("Receipt No.", '');
                if "Document Type" = "Document Type"::Order then
                    TestField("Quantity Received", 0);

                if JobTaskIsSet then begin
                    CreateTempJobJnlLine(false);
                    TempJobJnlLine.Validate("Line Amount (LCY)", "Job Line Amount (LCY)");
                    UpdateJobPrices;
                end;
            end;
        }
        field(1011; "Job Line Disc. Amount (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Job Line Disc. Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                TestField("Receipt No.", '');
                if "Document Type" = "Document Type"::Order then
                    TestField("Quantity Received", 0);

                if JobTaskIsSet then begin
                    CreateTempJobJnlLine(false);
                    TempJobJnlLine.Validate("Line Discount Amount (LCY)", "Job Line Disc. Amount (LCY)");
                    UpdateJobPrices;
                end;
            end;
        }
        field(1012; "Job Currency Factor"; Decimal)
        {
            BlankZero = true;
            Caption = 'Job Currency Factor';
        }
        field(1013; "Job Currency Code"; Code[20])
        {
            Caption = 'Job Currency Code';
        }
        field(1019; "Job Planning Line No."; Integer)
        {
            AccessByPermission = TableData Job = R;
            BlankZero = true;
            Caption = 'Job Planning Line No.';

            trigger OnLookup()
            var
                JobPlanningLine: Record "Job Planning Line";
            begin
                JobPlanningLine.SetRange("Job No.", "Job No.");
                JobPlanningLine.SetRange("Job Task No.", "Job Task No.");
                case Type of
                    Type::"G/L Account":
                        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::"G/L Account");
                    Type::Item:
                        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);
                end;
                JobPlanningLine.SetRange("No.", "No.");
                JobPlanningLine.SetRange("Usage Link", true);
                JobPlanningLine.SetRange("System-Created Entry", false);

                if PAGE.RunModal(0, JobPlanningLine) = ACTION::LookupOK then
                    Validate("Job Planning Line No.", JobPlanningLine."Line No.");
            end;

            trigger OnValidate()
            var
                JobPlanningLine: Record "Job Planning Line";
            begin
                if "Job Planning Line No." <> 0 then begin
                    JobPlanningLine.Get("Job No.", "Job Task No.", "Job Planning Line No.");
                    JobPlanningLine.TestField("Job No.", "Job No.");
                    JobPlanningLine.TestField("Job Task No.", "Job Task No.");
                    case Type of
                        Type::"G/L Account":
                            JobPlanningLine.TestField(Type, JobPlanningLine.Type::"G/L Account");
                        Type::Item:
                            JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
                    end;
                    JobPlanningLine.TestField("No.", "No.");
                    JobPlanningLine.TestField("Usage Link", true);
                    JobPlanningLine.TestField("System-Created Entry", false);
                    "Job Line Type" := JobPlanningLine."Line Type" + 1;
                    Validate("Job Remaining Qty.", JobPlanningLine."Remaining Qty." - "Qty. to Invoice");
                end else
                    Validate("Job Remaining Qty.", 0);
            end;
        }
        field(1030; "Job Remaining Qty."; Decimal)
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Job Remaining Qty.';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                JobPlanningLine: Record "Job Planning Line";
            begin
                if ("Job Remaining Qty." <> 0) and ("Job Planning Line No." = 0) then
                    Error(Text047, FieldCaption("Job Remaining Qty."), FieldCaption("Job Planning Line No."));

                if "Job Planning Line No." <> 0 then begin
                    JobPlanningLine.Get("Job No.", "Job Task No.", "Job Planning Line No.");
                    if JobPlanningLine.Quantity >= 0 then begin
                        if "Job Remaining Qty." < 0 then
                            "Job Remaining Qty." := 0;
                    end else begin
                        if "Job Remaining Qty." > 0 then
                            "Job Remaining Qty." := 0;
                    end;
                end;
                "Job Remaining Qty. (Base)" :=
                    UOMMgt.CalcBaseQty("No.", "Variant Code", "Unit of Measure Code", "Job Remaining Qty.", "Qty. per Unit of Measure");
            end;
        }
        field(1031; "Job Remaining Qty. (Base)"; Decimal)
        {
            Caption = 'Job Remaining Qty. (Base)';
        }
        field(1700; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            TableRelation = "Deferral Template"."Deferral Code";

            trigger OnValidate()
            var
                DeferralPostDate: Date;
            begin
                GetPurchHeader;
                DeferralPostDate := PurchHeader."Posting Date";

                DeferralUtilities.DeferralCodeOnValidate(
                  "Deferral Code", DeferralUtilities.GetPurchDeferralDocType, '', '',
                  "Document Type", "Document No.", "Line No.",
                  GetDeferralAmount(), DeferralPostDate,
                  Description, PurchHeader."Currency Code");

                if "Document Type" = "Document Type"::"Return Order" then
                    "Returns Deferral Start Date" :=
                      DeferralUtilities.GetDeferralStartDate(DeferralUtilities.GetPurchDeferralDocType,
                        "Document Type", "Document No.", "Line No.", "Deferral Code", PurchHeader."Posting Date");
            end;
        }
        field(1702; "Returns Deferral Start Date"; Date)
        {
            Caption = 'Returns Deferral Start Date';

            trigger OnValidate()
            var
                DeferralHeader: Record "Deferral Header";
                DeferralUtilities: Codeunit "Deferral Utilities";
            begin
                GetPurchHeader;
                if DeferralHeader.Get(DeferralUtilities.GetPurchDeferralDocType, '', '', "Document Type", "Document No.", "Line No.") then
                    DeferralUtilities.CreateDeferralSchedule("Deferral Code", DeferralUtilities.GetPurchDeferralDocType, '', '',
                      "Document Type", "Document No.", "Line No.", GetDeferralAmount(),
                      DeferralHeader."Calc. Method", "Returns Deferral Start Date",
                      DeferralHeader."No. of Periods", true,
                      DeferralHeader."Schedule Description", false,
                      PurchHeader."Currency Code");
            end;
        }
        field(5401; "Prod. Order No."; Code[20])
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Prod. Order No.';
            Editable = false;
            TableRelation = "Production Order"."No." WHERE(Status = CONST(Released));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if "Drop Shipment" then
                    Error(
                      Text001,
                      FieldCaption("Prod. Order No."), "Sales Order No.");

                AddOnIntegrMgt.ValidateProdOrderOnPurchLine(Rec);
            end;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = IF (Type = CONST(Item)) "Item Variant".Code WHERE("Item No." = FIELD("No."));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if "Variant Code" <> '' then
                    TestField(Type, Type::Item);
                TestStatusOpen;

                if xRec."Variant Code" <> "Variant Code" then begin
                    TestField("Qty. Rcd. Not Invoiced", 0);
                    TestField("Receipt No.", '');
                    TestField("Return Qty. Shipped Not Invd.", 0);
                    TestField("Return Shipment No.", '');
                end;

                IsHandled := false;
                OnValidateVariantCodeOnBeforeDropShipmentError(Rec, IsHandled);
                if not IsHandled then
                    if "Drop Shipment" then
                        Error(Text001, FieldCaption("Variant Code"), "Sales Order No.");

                OnValidateVariantCodeOnAfterValidationChecks(Rec, xRec, CurrFieldNo);

                if Type = Type::Item then
                    if "Variant Code" <> xRec."Variant Code" then
                        PlanPriceCalcByField(FieldNo("Variant Code"));

                if (xRec."Variant Code" <> "Variant Code") and (Quantity <> 0) then begin
                    ReservePurchLine.VerifyChange(Rec, xRec);
                    WhseValidateSourceLine.PurchaseLineVerifyChange(Rec, xRec);
                    InitItemAppl;
                end;

                UpdateLeadTimeFields;
                UpdateDates;
                GetDefaultBin;
                if Type = Type::Item then
                    UpdateItemReference;

                if JobTaskIsSet then begin
                    CreateTempJobJnlLine(true);
                    UpdateJobPrices;
                end;
                UpdateDirectUnitCostByField(FieldNo("Variant Code"));
            end;
        }
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = IF ("Document Type" = FILTER(Order | Invoice),
                                Quantity = FILTER(< 0)) "Bin Content"."Bin Code" WHERE("Location Code" = FIELD("Location Code"),
                                                                                     "Item No." = FIELD("No."),
                                                                                     "Variant Code" = FIELD("Variant Code"))
            ELSE
            IF ("Document Type" = FILTER("Return Order" | "Credit Memo"),
                                                                                              Quantity = FILTER(>= 0)) "Bin Content"."Bin Code" WHERE("Location Code" = FIELD("Location Code"),
                                                                                                                                                    "Item No." = FIELD("No."),
                                                                                                                                                    "Variant Code" = FIELD("Variant Code"))
            ELSE
            Bin.Code WHERE("Location Code" = FIELD("Location Code"));

            trigger OnLookup()
            var
                WMSManagement: Codeunit "WMS Management";
                BinCode: Code[20];
            begin
                if not IsInbound and ("Quantity (Base)" <> 0) then
                    BinCode := WMSManagement.BinContentLookUp("Location Code", "No.", "Variant Code", '', "Bin Code")
                else
                    BinCode := WMSManagement.BinLookUp("Location Code", "No.", "Variant Code", '');

                if BinCode <> '' then
                    Validate("Bin Code", BinCode);
            end;

            trigger OnValidate()
            var
                WMSManagement: Codeunit "WMS Management";
            begin
                if "Bin Code" <> '' then begin
                    if not IsInbound and ("Quantity (Base)" <> 0) then
                        WMSManagement.FindBinContent("Location Code", "Bin Code", "No.", "Variant Code", '')
                    else
                        WMSManagement.FindBin("Location Code", "Bin Code", '');
                end;

                if "Drop Shipment" then
                    Error(
                      Text001,
                      FieldCaption("Bin Code"), "Sales Order No.");

                TestField(Type, Type::Item);
                TestField("Location Code");

                if "Bin Code" <> '' then begin
                    GetLocation("Location Code");
                    Location.TestField("Bin Mandatory");
                    CheckWarehouse;
                end;
            end;
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = IF (Type = CONST(Item),
                                "No." = FILTER(<> '')) "Item Unit of Measure".Code WHERE("Item No." = FIELD("No."))
            ELSE
            if (Type = const(Resource), "No." = filter(<> '')) "Resource Unit of Measure".Code where("Resource No." = field("No."))
            else
            "Unit of Measure";

            trigger OnValidate()
            var
                Item: Record Item;
                UnitOfMeasureTranslation: Record "Unit of Measure Translation";
                Resource: Record Resource;
                IsHandled: Boolean;
            begin
                TestStatusOpen;
                TestField("Quantity Received", 0);
                TestField("Qty. Received (Base)", 0);
                TestField("Qty. Rcd. Not Invoiced", 0);
                TestField("Return Qty. Shipped", 0);
                TestField("Return Qty. Shipped (Base)", 0);
                if "Unit of Measure Code" <> xRec."Unit of Measure Code" then begin
                    TestField("Receipt No.", '');
                    TestField("Return Shipment No.", '');
                end;

                IsHandled := false;
                OnValidateUnitOfMeasureCodeOnBeforeDropShipmentError(Rec, IsHandled, xRec, CurrFieldNo);
                if not IsHandled then
                    if "Drop Shipment" then
                        Error(Text001, FieldCaption("Unit of Measure Code"), "Sales Order No.");

                if (xRec."Unit of Measure Code" <> "Unit of Measure Code") and (Quantity <> 0) then begin
                    WhseValidateSourceLine.PurchaseLineVerifyChange(Rec, xRec);
                    PlanPriceCalcByField(FieldNo("Unit of Measure Code"));
                end;
                if "Unit of Measure Code" = '' then
                    "Unit of Measure" := ''
                else begin
                    UnitOfMeasure.Get("Unit of Measure Code");
                    "Unit of Measure" := UnitOfMeasure.Description;
                    GetPurchHeader;
                    if PurchHeader."Language Code" <> '' then begin
                        UnitOfMeasureTranslation.SetRange(Code, "Unit of Measure Code");
                        UnitOfMeasureTranslation.SetRange("Language Code", PurchHeader."Language Code");
                        if UnitOfMeasureTranslation.FindFirst then
                            "Unit of Measure" := UnitOfMeasureTranslation.Description;
                    end;
                end;
                if Type = Type::Item then
                    UpdateItemReference;
                if "Prod. Order No." = '' then
                    case Type of
                        Type::Item:
                            begin
                                GetItem(Item);
                                "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                                "Gross Weight" := Item."Gross Weight" * "Qty. per Unit of Measure";
                                "Net Weight" := Item."Net Weight" * "Qty. per Unit of Measure";
                                "Unit Volume" := Item."Unit Volume" * "Qty. per Unit of Measure";
                                "Units per Parcel" := Round(Item."Units per Parcel" / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
                                OnAfterAssignItemUOM(Rec, Item, CurrFieldNo);
                                if "Qty. per Unit of Measure" > xRec."Qty. per Unit of Measure" then
                                    InitItemAppl;
                                UpdateUOMQtyPerStockQty;
                            end;
                        Type::Resource:
                            begin
                                GetResource(Resource);
                                "Qty. per Unit of Measure" := UoMMgt.GetResQtyPerUnitOfMeasure(Resource, "Unit of Measure Code");
                                OnAfterAssignResourceUOM(Rec, Resource, CurrFieldNo);
                                if "Unit of Measure Code" <> xRec."Unit of Measure Code" then
                                    PlanPriceCalcByField(FieldNo("Unit of Measure Code"));
                            end;
                        Type::" ",
                        Type::"Charge (Item)",
                        Type::"Fixed Asset",
                        Type::"G/L Account":
                            "Qty. per Unit of Measure" := 1;
                    end
                else
                    "Qty. per Unit of Measure" := 0;

                Validate(Quantity);
                UpdateDirectUnitCostByField(FieldNo("Unit of Measure Code"));
            end;
        }
        field(5415; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                if "Quantity (Base)" <> xRec."Quantity (Base)" then
                    PlanPriceCalcByField(FieldNo("Quantity (Base)"));
                Validate(Quantity, "Quantity (Base)");
                UpdateDirectUnitCostByField(FieldNo("Quantity (Base)"));
            end;
        }
        field(5416; "Outstanding Qty. (Base)"; Decimal)
        {
            Caption = 'Outstanding Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5417; "Qty. to Invoice (Base)"; Decimal)
        {
            Caption = 'Qty. to Invoice (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Invoice", "Qty. to Invoice (Base)");
            end;
        }
        field(5418; "Qty. to Receive (Base)"; Decimal)
        {
            Caption = 'Qty. to Receive (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Receive", "Qty. to Receive (Base)");
            end;
        }
        field(5458; "Qty. Rcd. Not Invoiced (Base)"; Decimal)
        {
            Caption = 'Qty. Rcd. Not Invoiced (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5460; "Qty. Received (Base)"; Decimal)
        {
            Caption = 'Qty. Received (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5461; "Qty. Invoiced (Base)"; Decimal)
        {
            Caption = 'Qty. Invoiced (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5495; "Reserved Qty. (Base)"; Decimal)
        {
            CalcFormula = Sum ("Reservation Entry"."Quantity (Base)" WHERE("Source Type" = CONST(39),
                                                                           "Source Subtype" = FIELD("Document Type"),
                                                                           "Source ID" = FIELD("Document No."),
                                                                           "Source Ref. No." = FIELD("Line No."),
                                                                           "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5600; "FA Posting Date"; Date)
        {
            Caption = 'FA Posting Date';
        }
        field(5601; "FA Posting Type"; Option)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'FA Posting Type';
            OptionCaption = ' ,Acquisition Cost,Maintenance,,Appreciation';
            OptionMembers = " ","Acquisition Cost",Maintenance,,Appreciation;

            trigger OnValidate()
            begin
                if Type = Type::"Fixed Asset" then begin
                    TestField("Job No.", '');
                    if "FA Posting Type" = "FA Posting Type"::" " then
                        "FA Posting Type" := "FA Posting Type"::"Acquisition Cost";
                    GetFAPostingGroup;
                end else begin
                    "Depreciation Book Code" := '';
                    "FA Posting Date" := 0D;
                    "Salvage Value" := 0;
                    "Depr. until FA Posting Date" := false;
                    "Depr. Acquisition Cost" := false;
                    "Maintenance Code" := '';
                    "Insurance No." := '';
                    "Budgeted FA No." := '';
                    "Duplicate in Depreciation Book" := '';
                    "Use Duplication List" := false;
                end;
            end;
        }
        field(5602; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";

            trigger OnValidate()
            begin
                GetFAPostingGroup;
            end;
        }
        field(5603; "Salvage Value"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Salvage Value';
        }
        field(5605; "Depr. until FA Posting Date"; Boolean)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'Depr. until FA Posting Date';
        }
        field(5606; "Depr. Acquisition Cost"; Boolean)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'Depr. Acquisition Cost';
        }
        field(5609; "Maintenance Code"; Code[10])
        {
            Caption = 'Maintenance Code';
            TableRelation = Maintenance;
        }
        field(5610; "Insurance No."; Code[20])
        {
            Caption = 'Insurance No.';
            TableRelation = Insurance;
        }
        field(5611; "Budgeted FA No."; Code[20])
        {
            Caption = 'Budgeted FA No.';
            TableRelation = "Fixed Asset";

            trigger OnValidate()
            var
                FixedAsset: Record "Fixed Asset";
            begin
                if "Budgeted FA No." <> '' then begin
                    FixedAsset.Get("Budgeted FA No.");
                    FixedAsset.TestField("Budgeted Asset", true);
                end;
            end;
        }
        field(5612; "Duplicate in Depreciation Book"; Code[10])
        {
            Caption = 'Duplicate in Depreciation Book';
            TableRelation = "Depreciation Book";

            trigger OnValidate()
            begin
                "Use Duplication List" := false;
            end;
        }
        field(5613; "Use Duplication List"; Boolean)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'Use Duplication List';

            trigger OnValidate()
            begin
                "Duplicate in Depreciation Book" := '';
            end;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            Editable = false;
            TableRelation = "Responsibility Center";

            trigger OnValidate()
            begin
                CreateDim(
                  DATABASE::"Responsibility Center", "Responsibility Center",
                  DimMgt.TypeToTableID3(Type), "No.",
                  DATABASE::Job, "Job No.",
                  DATABASE::"Work Center", "Work Center No.");
            end;
        }
        field(5705; "Cross-Reference No."; Code[20])
        {
            AccessByPermission = TableData "Item Cross Reference" = R;
            Caption = 'Cross-Reference No.';

            trigger OnLookup()
            begin
                CrossReferenceNoLookUp;
            end;

            trigger OnValidate()
            var
                ItemCrossReference: Record "Item Cross Reference";
            begin
                GetPurchHeader;
                "Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";
                ValidateCrossReferenceNo(ItemCrossReference, true);
            end;
        }
        field(5706; "Unit of Measure (Cross Ref.)"; Code[10])
        {
            Caption = 'Unit of Measure (Cross Ref.)';
            TableRelation = IF (Type = CONST(Item)) "Item Unit of Measure".Code WHERE("Item No." = FIELD("No."));
        }
        field(5707; "Cross-Reference Type"; Option)
        {
            Caption = 'Cross-Reference Type';
            OptionCaption = ' ,Customer,Vendor,Bar Code';
            OptionMembers = " ",Customer,Vendor,"Bar Code";
        }
        field(5708; "Cross-Reference Type No."; Code[30])
        {
            Caption = 'Cross-Reference Type No.';
        }
        field(5709; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";
        }
        field(5710; Nonstock; Boolean)
        {
            AccessByPermission = TableData "Nonstock Item" = R;
            Caption = 'Catalog';
        }
        field(5711; "Purchasing Code"; Code[10])
        {
            Caption = 'Purchasing Code';
            Editable = false;
            TableRelation = Purchasing;

            trigger OnValidate()
            var
                PurchasingCode: Record Purchasing;
            begin
                if PurchasingCode.Get("Purchasing Code") then begin
                    "Drop Shipment" := PurchasingCode."Drop Shipment";
                    "Special Order" := PurchasingCode."Special Order";
                    OnValidatePurchasingCodeOnAfterAssignFields(Rec, PurchasingCode);
                end else
                    "Drop Shipment" := false;

                Validate("Drop Shipment", "Drop Shipment");
            end;
        }
        field(5712; "Product Group Code"; Code[10])
        {
            Caption = 'Product Group Code';
            ObsoleteReason = 'Product Groups became first level children of Item Categories.';
            ObsoleteState = Removed;
            TableRelation = "Product Group".Code WHERE("Item Category Code" = FIELD("Item Category Code"));
            ValidateTableRelation = false;
            ObsoleteTag = '15.0';
        }
        field(5713; "Special Order"; Boolean)
        {
            Caption = 'Special Order';

            trigger OnValidate()
            begin
                if (xRec."Special Order" <> "Special Order") and (Quantity <> 0) then
                    WhseValidateSourceLine.PurchaseLineVerifyChange(Rec, xRec);
            end;
        }
        field(5714; "Special Order Sales No."; Code[20])
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Special Order Sales No.';
            TableRelation = IF ("Special Order" = CONST(true)) "Sales Header"."No." WHERE("Document Type" = CONST(Order));

            trigger OnValidate()
            begin
                if (xRec."Special Order Sales No." <> "Special Order Sales No.") and (Quantity <> 0) then
                    WhseValidateSourceLine.PurchaseLineVerifyChange(Rec, xRec);
            end;
        }
        field(5715; "Special Order Sales Line No."; Integer)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Special Order Sales Line No.';
            TableRelation = IF ("Special Order" = CONST(true)) "Sales Line"."Line No." WHERE("Document Type" = CONST(Order),
                                                                                            "Document No." = FIELD("Special Order Sales No."));

            trigger OnValidate()
            begin
                if (xRec."Special Order Sales Line No." <> "Special Order Sales Line No.") and (Quantity <> 0) then
                    WhseValidateSourceLine.PurchaseLineVerifyChange(Rec, xRec);
            end;
        }
        field(5750; "Whse. Outstanding Qty. (Base)"; Decimal)
        {
            AccessByPermission = TableData Location = R;
            BlankZero = true;
            CalcFormula = Sum ("Warehouse Receipt Line"."Qty. Outstanding (Base)" WHERE("Source Type" = CONST(39),
                                                                                        "Source Subtype" = FIELD("Document Type"),
                                                                                        "Source No." = FIELD("Document No."),
                                                                                        "Source Line No." = FIELD("Line No.")));
            Caption = 'Whse. Outstanding Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5752; "Completely Received"; Boolean)
        {
            Caption = 'Completely Received';
            Editable = false;
        }
        field(5790; "Requested Receipt Date"; Date)
        {
            Caption = 'Requested Receipt Date';

            trigger OnValidate()
            var
                CustomCalendarChange: Array[2] of Record "Customized Calendar Change";
            begin
                TestStatusOpen;
                if (CurrFieldNo <> 0) and
                   ("Promised Receipt Date" <> 0D)
                then
                    Error(
                      Text023,
                      FieldCaption("Requested Receipt Date"),
                      FieldCaption("Promised Receipt Date"));

                if "Requested Receipt Date" <> 0D then begin
                    CustomCalendarChange[1].SetSource(CalChange."Source Type"::Vendor, "Buy-from Vendor No.", '', '');
                    CustomCalendarChange[2].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
                    Validate("Order Date",
                      CalendarMgmt.CalcDateBOC2(AdjustDateFormula("Lead Time Calculation"), "Requested Receipt Date", CustomCalendarChange, true))
                end else
                    if "Requested Receipt Date" <> xRec."Requested Receipt Date" then
                        GetUpdateBasicDates;
            end;
        }
        field(5791; "Promised Receipt Date"; Date)
        {
            AccessByPermission = TableData "Order Promising Line" = R;
            Caption = 'Promised Receipt Date';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePromisedReceiptDate(Rec, CurrFieldNo, IsHandled);
                If IsHandled then
                    exit;

                if CurrFieldNo <> 0 then
                    if "Promised Receipt Date" <> 0D then
                        Validate("Planned Receipt Date", "Promised Receipt Date")
                    else
                        Validate("Requested Receipt Date")
                else
                    Validate("Planned Receipt Date", "Promised Receipt Date");
            end;
        }
        field(5792; "Lead Time Calculation"; DateFormula)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Lead Time Calculation';

            trigger OnValidate()
            begin
                TestStatusOpen;
                LeadTimeMgt.CheckLeadTimeIsNotNegative("Lead Time Calculation");

                if "Requested Receipt Date" <> 0D then
                    Validate("Planned Receipt Date")
                else
                    GetUpdateBasicDates;
            end;
        }
        field(5793; "Inbound Whse. Handling Time"; DateFormula)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Inbound Whse. Handling Time';

            trigger OnValidate()
            begin
                TestStatusOpen;
                if ("Promised Receipt Date" <> 0D) or
                   ("Requested Receipt Date" <> 0D)
                then
                    Validate("Planned Receipt Date")
                else
                    Validate("Expected Receipt Date");
            end;
        }
        field(5794; "Planned Receipt Date"; Date)
        {
            AccessByPermission = TableData "Order Promising Line" = R;
            Caption = 'Planned Receipt Date';

            trigger OnValidate()
            var
                CustomCalendarChange: Array[2] of Record "Customized Calendar Change";
            begin
                TestStatusOpen;
                if "Promised Receipt Date" <> 0D then begin
                    if "Planned Receipt Date" <> 0D then begin
                        CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
                        "Expected Receipt Date" :=
                          CalendarMgmt.CalcDateBOC(InternalLeadTimeDays("Planned Receipt Date"), "Planned Receipt Date", CustomCalendarChange, false)
                    end else
                        "Expected Receipt Date" := "Planned Receipt Date";
                end else
                    if "Planned Receipt Date" <> 0D then begin
                        CustomCalendarChange[1].SetSource(CalChange."Source Type"::Vendor, "Buy-from Vendor No.", '', '');
                        CustomCalendarChange[2].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
                        "Order Date" :=
                          CalendarMgmt.CalcDateBOC2(AdjustDateFormula("Lead Time Calculation"), "Planned Receipt Date", CustomCalendarChange, true);
                        CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
                        "Expected Receipt Date" :=
                          CalendarMgmt.CalcDateBOC(InternalLeadTimeDays("Planned Receipt Date"), "Planned Receipt Date", CustomCalendarChange, false)
                    end else
                        GetUpdateBasicDates;

                if not TrackingBlocked then
                    CheckDateConflict.PurchLineCheck(Rec, CurrFieldNo <> 0);
            end;
        }
        field(5795; "Order Date"; Date)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Order Date';

            trigger OnValidate()
            var
                CustomCalendarChange: Array[2] of Record "Customized Calendar Change";
            begin
                TestStatusOpen;
                if (CurrFieldNo <> 0) and
                   ("Document Type" = "Document Type"::Order) and
                   ("Order Date" < WorkDate) and
                   ("Order Date" <> 0D)
                then
                    Message(
                      Text018,
                      FieldCaption("Order Date"), "Order Date", WorkDate);

                if "Order Date" <> 0D then begin
                    CustomCalendarChange[1].SetSource(CalChange."Source Type"::Vendor, "Buy-from Vendor No.", '', '');
                    CustomCalendarChange[2].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
                    "Planned Receipt Date" :=
                      CalendarMgmt.CalcDateBOC(AdjustDateFormula("Lead Time Calculation"), "Order Date", CustomCalendarChange, true);
                end;

                if "Planned Receipt Date" <> 0D then begin
                    CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
                    "Expected Receipt Date" :=
                      CalendarMgmt.CalcDateBOC(InternalLeadTimeDays("Planned Receipt Date"), "Planned Receipt Date", CustomCalendarChange, false)
                end else
                    "Expected Receipt Date" := "Planned Receipt Date";

                if not TrackingBlocked then
                    CheckDateConflict.PurchLineCheck(Rec, CurrFieldNo <> 0);
            end;
        }
        field(5800; "Allow Item Charge Assignment"; Boolean)
        {
            AccessByPermission = TableData "Item Charge" = R;
            Caption = 'Allow Item Charge Assignment';
            InitValue = true;

            trigger OnValidate()
            begin
                CheckItemChargeAssgnt;
            end;
        }
        field(5801; "Qty. to Assign"; Decimal)
        {
            CalcFormula = Sum ("Item Charge Assignment (Purch)"."Qty. to Assign" WHERE("Document Type" = FIELD("Document Type"),
                                                                                       "Document No." = FIELD("Document No."),
                                                                                       "Document Line No." = FIELD("Line No.")));
            Caption = 'Qty. to Assign';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5802; "Qty. Assigned"; Decimal)
        {
            CalcFormula = Sum ("Item Charge Assignment (Purch)"."Qty. Assigned" WHERE("Document Type" = FIELD("Document Type"),
                                                                                      "Document No." = FIELD("Document No."),
                                                                                      "Document Line No." = FIELD("Line No.")));
            Caption = 'Qty. Assigned';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5803; "Return Qty. to Ship"; Decimal)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            Caption = 'Return Qty. to Ship';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if (CurrFieldNo <> 0) and
                   (Type = Type::Item) and
                   ("Return Qty. to Ship" <> 0) and
                   (not "Drop Shipment")
                then
                    CheckWarehouse;

                OnValidateReturnQtyToShipOnAfterCheck(Rec, CurrFieldNo);

                if "Return Qty. to Ship" = Quantity - "Return Qty. Shipped" then
                    InitQtyToShip
                else begin
                    "Return Qty. to Ship (Base)" :=
                        UOMMgt.CalcBaseQty("No.", "Variant Code", "Unit of Measure Code", "Return Qty. to Ship", "Qty. per Unit of Measure");
                    InitQtyToInvoice;
                end;

                IsHandled := false;
                OnValidateReturnQtyToShipOnAfterInitQty(Rec, xRec, CurrFieldNo, IsHandled);
                if not IsHandled then begin
                    if ("Return Qty. to Ship" * Quantity < 0) or
                       (Abs("Return Qty. to Ship") > Abs("Outstanding Quantity")) or
                       (Quantity * "Outstanding Quantity" < 0)
                    then
                        Error(Text020, "Outstanding Quantity");
                    if ("Return Qty. to Ship (Base)" * "Quantity (Base)" < 0) or
                       (Abs("Return Qty. to Ship (Base)") > Abs("Outstanding Qty. (Base)")) or
                       ("Quantity (Base)" * "Outstanding Qty. (Base)" < 0)
                    then
                        Error(Text021, "Outstanding Qty. (Base)");
                end;

                if (CurrFieldNo <> 0) and (Type = Type::Item) and ("Return Qty. to Ship" > 0) then
                    CheckApplToItemLedgEntry;
            end;
        }
        field(5804; "Return Qty. to Ship (Base)"; Decimal)
        {
            Caption = 'Return Qty. to Ship (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate("Return Qty. to Ship", "Return Qty. to Ship (Base)");
            end;
        }
        field(5805; "Return Qty. Shipped Not Invd."; Decimal)
        {
            Caption = 'Return Qty. Shipped Not Invd.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5806; "Ret. Qty. Shpd Not Invd.(Base)"; Decimal)
        {
            Caption = 'Ret. Qty. Shpd Not Invd.(Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5807; "Return Shpd. Not Invd."; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Return Shpd. Not Invd.';
            Editable = false;

            trigger OnValidate()
            var
                Currency2: Record Currency;
            begin
                GetPurchHeader;
                Currency2.InitRoundingPrecision;
                if PurchHeader."Currency Code" <> '' then
                    "Return Shpd. Not Invd. (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          GetDate, "Currency Code",
                          "Return Shpd. Not Invd.", PurchHeader."Currency Factor"),
                        Currency2."Amount Rounding Precision")
                else
                    "Return Shpd. Not Invd. (LCY)" :=
                      Round("Return Shpd. Not Invd.", Currency2."Amount Rounding Precision");
            end;
        }
        field(5808; "Return Shpd. Not Invd. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Return Shpd. Not Invd. (LCY)';
            Editable = false;
        }
        field(5809; "Return Qty. Shipped"; Decimal)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            Caption = 'Return Qty. Shipped';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5810; "Return Qty. Shipped (Base)"; Decimal)
        {
            Caption = 'Return Qty. Shipped (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(6600; "Return Shipment No."; Code[20])
        {
            Caption = 'Return Shipment No.';
            Editable = false;
        }
        field(6601; "Return Shipment Line No."; Integer)
        {
            Caption = 'Return Shipment Line No.';
            Editable = false;
        }
        field(6608; "Return Reason Code"; Code[10])
        {
            Caption = 'Return Reason Code';
            TableRelation = "Return Reason";

            trigger OnValidate()
            begin
                ValidateReturnReasonCode(FieldNo("Return Reason Code"));
            end;
        }
        field(6609; Subtype; Option)
        {
            Caption = 'Subtype';
            OptionCaption = ' ,Item - Inventory,Item - Service,Comment';
            OptionMembers = " ","Item - Inventory","Item - Service",Comment;
        }
        field(6610; "Copied From Posted Doc."; Boolean)
        {
            Caption = 'Copied From Posted Doc.';
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        field(7010; "Attached Doc Count"; Integer)
        {
            BlankNumbers = DontBlank;
            CalcFormula = Count ("Document Attachment" WHERE("Table ID" = CONST(39),
                                                             "No." = FIELD("Document No."),
                                                             "Document Type" = FIELD("Document Type"),
                                                             "Line No." = FIELD("Line No.")));
            Caption = 'Attached Doc Count';
            FieldClass = FlowField;
            InitValue = 0;
        }
        field(8509; "Over-Receipt Quantity"; Decimal)
        {
            Caption = 'Over-Receipt Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                OverReceiptCode: Record "Over-Receipt Code";
                PurchaseHeader: Record "Purchase Header";
                OverReceiptMgt: Codeunit "Over-Receipt Mgt.";
                Handled: Boolean;
            begin
                OnValidateOverReceiptQuantity(Rec, xRec, CurrFieldNo, Handled);
                if Handled then
                    exit;
                if not OverReceiptMgt.IsOverReceiptAllowed() then begin
                    "Over-Receipt Quantity" := 0;
                    "Over-Receipt Approval Status" := "Over-Receipt Approval Status"::" ";
                    exit;
                end;
                if CurrFieldNo = FieldNo("Over-Receipt Quantity") then
                    if xRec."Over-Receipt Quantity" = "Over-Receipt Quantity" then
                        exit;
                PurchaseHeader.Get("Document Type", "Document No.");
                PurchaseHeader.TestField("Document Type", PurchHeader."Document Type"::Order);
                PurchaseHeader.TestField(Status, PurchHeader.Status::Released);
                TestField(Type, Type::Item);
                TestField("No.");
                if "Over-Receipt Code" = '' then
                    "Over-Receipt Code" := OverReceiptMgt.GetDefaultOverReceiptCode(Rec);
                TestField("Over-Receipt Code");
                if (CurrFieldNo <> FieldNo("Over-Receipt Quantity")) and (CurrFieldNo <> 0) then
                    "Over-Receipt Quantity" += xRec."Over-Receipt Quantity";
                OverReceiptMgt.VerifyOverReceiptQuantity(Rec, xRec);
                OverReceiptCode.Get("Over-Receipt Code");
                if OverReceiptCode."Required Approval" then
                    "Over-Receipt Approval Status" := "Over-Receipt Approval Status"::Pending;
                SuspendStatusCheck(true);
                if (CurrFieldNo = FieldNo("Over-Receipt Quantity")) or (CurrFieldNo = 0) or (CurrFieldNo = FieldNo("Qty. to Receive")) then
                    Validate(Quantity, Quantity - xRec."Over-Receipt Quantity" + "Over-Receipt Quantity");
                Validate("Direct Unit Cost");
                if "Over-Receipt Quantity" = 0 then begin
                    "Over-Receipt Approval Status" := "Over-Receipt Approval Status"::" ";
                    OverReceiptMgt.RecallOverReceiptNotification(PurchaseHeader.RecordId());
                end else
                    OverReceiptMgt.ShowOverReceiptNotificationFromLine(PurchaseHeader."No.");
            end;
        }
        field(8510; "Over-Receipt Code"; Code[20])
        {
            Caption = 'Over-Receipt Code';
            TableRelation = "Over-Receipt Code";
        }
        field(8511; "Over-Receipt Approval Status"; Enum "Over-Receipt Approval Status")
        {
            Caption = 'Over-Receipt Approval Status';
        }
        field(99000750; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            TableRelation = "Routing Header";
        }
        field(99000751; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            Editable = false;
            TableRelation = "Prod. Order Routing Line"."Operation No." WHERE(Status = CONST(Released),
                                                                              "Prod. Order No." = FIELD("Prod. Order No."),
                                                                              "Routing No." = FIELD("Routing No."));

            trigger OnValidate()
            var
                ProdOrderRtngLine: Record "Prod. Order Routing Line";
            begin
                if "Operation No." = '' then
                    exit;

                TestField(Type, Type::Item);
                TestField("Prod. Order No.");
                TestField("Routing No.");

                ProdOrderRtngLine.Get(
                  ProdOrderRtngLine.Status::Released,
                  "Prod. Order No.",
                  "Routing Reference No.",
                  "Routing No.",
                  "Operation No.");

                ProdOrderRtngLine.TestField(
                  Type,
                  ProdOrderRtngLine.Type::"Work Center");

                "Expected Receipt Date" := ProdOrderRtngLine."Ending Date";
                Validate("Work Center No.", ProdOrderRtngLine."No.");
                Validate("Direct Unit Cost", ProdOrderRtngLine."Direct Unit Cost");
            end;
        }
        field(99000752; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            Editable = false;
            TableRelation = "Work Center";

            trigger OnValidate()
            begin
                if Type = Type::"Charge (Item)" then
                    TestField("Work Center No.", '');
                if "Work Center No." = '' then
                    exit;

                WorkCenter.Get("Work Center No.");
                "Gen. Prod. Posting Group" := WorkCenter."Gen. Prod. Posting Group";
                "VAT Prod. Posting Group" := '';
                if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                    "VAT Prod. Posting Group" := GenProdPostingGrp."Def. VAT Prod. Posting Group";
                Validate("VAT Prod. Posting Group");

                "Overhead Rate" := WorkCenter."Overhead Rate";
                Validate("Indirect Cost %", WorkCenter."Indirect Cost %");

                CreateDim(
                  DATABASE::"Work Center", "Work Center No.",
                  DimMgt.TypeToTableID3(Type), "No.",
                  DATABASE::Job, "Job No.",
                  DATABASE::"Responsibility Center", "Responsibility Center");
            end;
        }
        field(99000753; Finished; Boolean)
        {
            Caption = 'Finished';
        }
        field(99000754; "Prod. Order Line No."; Integer)
        {
            Caption = 'Prod. Order Line No.';
            Editable = false;
            TableRelation = "Prod. Order Line"."Line No." WHERE(Status = FILTER(Released ..),
                                                                 "Prod. Order No." = FIELD("Prod. Order No."));
        }
        field(99000755; "Overhead Rate"; Decimal)
        {
            Caption = 'Overhead Rate';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Indirect Cost %");
            end;
        }
        field(99000756; "MPS Order"; Boolean)
        {
            Caption = 'MPS Order';
        }
        field(99000757; "Planning Flexibility"; Enum "Reservation Planning Flexibility")
        {
            Caption = 'Planning Flexibility';

            trigger OnValidate()
            begin
                if "Planning Flexibility" <> xRec."Planning Flexibility" then
                    ReservePurchLine.UpdatePlanningFlexibility(Rec);
            end;
        }
        field(99000758; "Safety Lead Time"; DateFormula)
        {
            Caption = 'Safety Lead Time';

            trigger OnValidate()
            begin
                Validate("Inbound Whse. Handling Time");
            end;
        }
        field(99000759; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "Line No.", "Document Type")
        {
            Enabled = false;
        }
        key(Key3; "Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Expected Receipt Date")
        {
            SumIndexFields = "Outstanding Qty. (Base)";
        }
        key(Key4; "Document Type", "Pay-to Vendor No.", "Currency Code", "Document No.")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Outstanding Amount", "Amt. Rcd. Not Invoiced", "Outstanding Amount (LCY)", "Amt. Rcd. Not Invoiced (LCY)";
        }
        key(Key5; "Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Location Code", "Expected Receipt Date")
        {
            Enabled = false;
            MaintainSIFTIndex = false;
            MaintainSQLIndex = false;
            SumIndexFields = "Outstanding Qty. (Base)";
        }
        key(Key6; "Document Type", "Pay-to Vendor No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Currency Code", "Document No.")
        {
            Enabled = false;
            MaintainSIFTIndex = false;
            MaintainSQLIndex = false;
            SumIndexFields = "Outstanding Amount", "Amt. Rcd. Not Invoiced", "Outstanding Amount (LCY)", "Amt. Rcd. Not Invoiced (LCY)";
        }
        key(Key7; "Document Type", "Blanket Order No.", "Blanket Order Line No.")
        {
        }
        key(Key8; "Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.")
        {
        }
        key(Key9; "Document Type", "Document No.", "Location Code")
        {
            MaintainSQLIndex = false;
            SumIndexFields = Amount, "Amount Including VAT";
        }
        key(Key10; "Document Type", "Receipt No.", "Receipt Line No.")
        {
        }
        key(Key11; Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Document Type", "Expected Receipt Date")
        {
            MaintainSQLIndex = false;
        }
        key(Key12; "Document Type", "Buy-from Vendor No.")
        {
        }
        key(Key13; "Document Type", "Job No.", "Job Task No.", "Document No.")
        {
            SumIndexFields = "Outstanding Amt. Ex. VAT (LCY)", "A. Rcd. Not Inv. Ex. VAT (LCY)";
        }
        key(Key14; "Document Type", "Document No.", Type, "No.")
        {
            Enabled = false;
        }
        key(Key15; "Document Type", Type, "No.")
        {
            Enabled = false;
            SumIndexFields = "Outstanding Qty. (Base)";
        }
        key(Key16; "Recalculate Invoice Disc.")
        {
        }
        key(Key17; "Outstanding Quantity")
        {
        }
        key(Key18; "Location Code", "Quantity Invoiced")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Line Amount", Quantity, "Unit of Measure Code")
        {
        }
    }

    trigger OnDelete()
    var
        PurchCommentLine: Record "Purch. Comment Line";
        SalesOrderLine: Record "Sales Line";
    begin
        TestStatusOpen;
        if (Quantity <> 0) and ItemExists("No.") then begin
            ReservePurchLine.DeleteLine(Rec);
            if "Receipt No." = '' then
                TestField("Qty. Rcd. Not Invoiced", 0);
            if "Return Shipment No." = '' then
                TestField("Return Qty. Shipped Not Invd.", 0);

            CalcFields("Reserved Qty. (Base)");
            TestField("Reserved Qty. (Base)", 0);
            WhseValidateSourceLine.PurchaseLineDelete(Rec);
        end;

        if ("Document Type" = "Document Type"::Order) and (Quantity <> "Quantity Invoiced") then
            TestField("Prepmt. Amt. Inv.", "Prepmt Amt Deducted");

        if "Sales Order Line No." <> 0 then begin
            LockTable();
            SalesOrderLine.LockTable();
            SalesOrderLine.Get(SalesOrderLine."Document Type"::Order, "Sales Order No.", "Sales Order Line No.");
            SalesOrderLine."Purchase Order No." := '';
            SalesOrderLine."Purch. Order Line No." := 0;
            SalesOrderLine.Modify();
        end;

        if ("Special Order Sales Line No." <> 0) and ("Quantity Invoiced" = 0) then begin
            LockTable();
            SalesOrderLine.LockTable();
            if SalesOrderLine.Get(
                 SalesOrderLine."Document Type"::Order, "Special Order Sales No.", "Special Order Sales Line No.")
            then begin
                SalesOrderLine."Special Order Purchase No." := '';
                SalesOrderLine."Special Order Purch. Line No." := 0;
                SalesOrderLine.Modify();
            end;
        end;

        CatalogItemMgt.DelNonStockPurch(Rec);

        if "Document Type" = "Document Type"::"Blanket Order" then begin
            PurchLine2.Reset();
            PurchLine2.SetCurrentKey("Document Type", "Blanket Order No.", "Blanket Order Line No.");
            PurchLine2.SetRange("Blanket Order No.", "Document No.");
            PurchLine2.SetRange("Blanket Order Line No.", "Line No.");
            OnDeleteOnAfterSetPurchLineFilters(PurchLine2);
            if PurchLine2.FindFirst then
                PurchLine2.TestField("Blanket Order Line No.", 0);
        end;

        if Type = Type::Item then
            DeleteItemChargeAssgnt("Document Type", "Document No.", "Line No.");

        if Type = Type::"Charge (Item)" then
            DeleteChargeChargeAssgnt("Document Type", "Document No.", "Line No.");

        if "Line No." <> 0 then begin
            PurchLine2.Reset();
            PurchLine2.SetRange("Document Type", "Document Type");
            PurchLine2.SetRange("Document No.", "Document No.");
            PurchLine2.SetRange("Attached to Line No.", "Line No.");
            PurchLine2.SetFilter("Line No.", '<>%1', "Line No.");
            PurchLine2.DeleteAll(true);
        end;

        PurchCommentLine.SetRange("Document Type", "Document Type");
        PurchCommentLine.SetRange("No.", "Document No.");
        PurchCommentLine.SetRange("Document Line No.", "Line No.");
        if not PurchCommentLine.IsEmpty then
            PurchCommentLine.DeleteAll();

        // In case we have roundings on VAT or Sales Tax, we should update some other line
        if (Type <> Type::" ") and ("Line No." <> 0) and ("Attached to Line No." = 0) and
           (Quantity <> 0) and (Amount <> 0) and (Amount <> "Amount Including VAT") and not StatusCheckSuspended
        then begin
            Quantity := 0;
            "Quantity (Base)" := 0;
            "Qty. to Invoice" := 0;
            "Qty. to Invoice (Base)" := 0;
            "Line Discount Amount" := 0;
            "Inv. Discount Amount" := 0;
            "Inv. Disc. Amount to Invoice" := 0;
            UpdateAmounts;
        end;

        if "Deferral Code" <> '' then
            DeferralUtilities.DeferralCodeOnDelete(
              DeferralUtilities.GetPurchDeferralDocType, '', '',
              "Document Type", "Document No.", "Line No.");
    end;

    trigger OnInsert()
    begin
        TestStatusOpen;
        if Quantity <> 0 then begin
            OnBeforeVerifyReservedQty(Rec, xRec, 0);
            ReservePurchLine.VerifyQuantity(Rec, xRec);
        end;
        LockTable();
        PurchHeader."No." := '';
        if ("Deferral Code" <> '') and (GetDeferralAmount() <> 0) then
            UpdateDeferralAmounts;
    end;

    trigger OnModify()
    begin
        if ("Document Type" = "Document Type"::"Blanket Order") and
           ((Type <> xRec.Type) or ("No." <> xRec."No."))
        then begin
            PurchLine2.Reset();
            PurchLine2.SetCurrentKey("Document Type", "Blanket Order No.", "Blanket Order Line No.");
            PurchLine2.SetRange("Blanket Order No.", "Document No.");
            PurchLine2.SetRange("Blanket Order Line No.", "Line No.");
            if PurchLine2.FindSet then
                repeat
                    PurchLine2.TestField(Type, Type);
                    PurchLine2.TestField("No.", "No.");
                until PurchLine2.Next = 0;
        end;

        if ((Quantity <> 0) or (xRec.Quantity <> 0)) and ItemExists(xRec."No.") then
            ReservePurchLine.VerifyChange(Rec, xRec);
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        Text000: Label 'You cannot rename a %1.';
        Text001: Label 'You cannot change %1 because the order line is associated with sales order %2.';
        Text002: Label 'Prices including VAT cannot be calculated when %1 is %2.';
        Text004: Label 'must not be less than %1';
        Text006: Label 'You cannot invoice more than %1 units.';
        Text007: Label 'You cannot invoice more than %1 base units.';
        Text008: Label 'You cannot receive more than %1 units.';
        Text009: Label 'You cannot receive more than %1 base units.';
        Text010: Label 'You cannot change %1 when %2 is %3.';
        Text011: Label ' must be 0 when %1 is %2';
        Text012: Label 'must not be specified when %1 = %2';
        Text016: Label '%1 is required for %2 = %3.';
        WhseRequirementMsg: Label '%1 is required for this line. The entered information may be disregarded by warehouse activities.', Comment = '%1=Document';
        Text018: Label '%1 %2 is earlier than the work date %3.';
        Text020: Label 'You cannot return more than %1 units.';
        Text021: Label 'You cannot return more than %1 base units.';
        Text022: Label 'You cannot change %1, if item charge is already posted.';
        Text023: Label 'You cannot change the %1 when the %2 has been filled in.';
        Text029: Label 'must be positive.';
        Text030: Label 'must be negative.';
        Text031: Label 'You cannot define item tracking on this line because it is linked to production order %1.';
        Text032: Label '%1 must not be greater than the sum of %2 and %3.';
        Text033: Label 'Warehouse ';
        Text034: Label 'Inventory ';
        Text035: Label '%1 units for %2 %3 have already been returned or transferred. Therefore, only %4 units can be returned.';
        Text037: Label 'cannot be %1.';
        Text038: Label 'cannot be less than %1.';
        Text039: Label 'cannot be more than %1.';
        Text040: Label 'You must use form %1 to enter %2, if item tracking is used.';
        ItemChargeAssignmentErr: Label 'You can only assign Item Charges for Line Types of Charge (Item).';
        Text99000000: Label 'You cannot change %1 when the purchase order is associated to a production order.';
        PurchHeader: Record "Purchase Header";
        PurchLine2: Record "Purchase Line";
        GLAcc: Record "G/L Account";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        VATPostingSetup: Record "VAT Posting Setup";
        GenBusPostingGrp: Record "Gen. Business Posting Group";
        GenProdPostingGrp: Record "Gen. Product Posting Group";
        UnitOfMeasure: Record "Unit of Measure";
        ItemCharge: Record "Item Charge";
        SKU: Record "Stockkeeping Unit";
        WorkCenter: Record "Work Center";
        InvtSetup: Record "Inventory Setup";
        Location: Record Location;
        GLSetup: Record "General Ledger Setup";
        CalChange: Record "Customized Calendar Change";
        TempJobJnlLine: Record "Job Journal Line" temporary;
        PurchSetup: Record "Purchases & Payables Setup";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        ReservePurchLine: Codeunit "Purch. Line-Reserve";
        UOMMgt: Codeunit "Unit of Measure Management";
        AddOnIntegrMgt: Codeunit AddOnIntegrManagement;
        DimMgt: Codeunit DimensionManagement;
        DistIntegration: Codeunit "Dist. Integration";
        CatalogItemMgt: Codeunit "Catalog Item Management";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        LeadTimeMgt: Codeunit "Lead-Time Management";
        CalendarMgmt: Codeunit "Calendar Management";
        CheckDateConflict: Codeunit "Reservation-Check Date Confl.";
        DeferralUtilities: Codeunit "Deferral Utilities";
        PostingSetupMgt: Codeunit PostingSetupManagement;
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        FieldCausedPriceCalculation: Integer;
        TrackingBlocked: Boolean;
        StatusCheckSuspended: Boolean;
        GLSetupRead: Boolean;
        UnitCostCurrency: Decimal;
        UpdateFromVAT: Boolean;
        Text042: Label 'You cannot return more than the %1 units that you have received for %2 %3.';
        Text043: Label 'must be positive when %1 is not 0.';
        Text044: Label 'You cannot change %1 because this purchase order is associated with %2 %3.';
        Text046: Label '%3 will not update %1 when changing %2 because a prepayment invoice has been posted. Do you want to continue?', Comment = '%1 - product name';
        Text047: Label '%1 can only be set when %2 is set.';
        Text048: Label '%1 cannot be changed when %2 is set.';
        PrePaymentLineAmountEntered: Boolean;
        Text049: Label 'You have changed one or more dimensions on the %1, which is already shipped. When you post the line with the changed dimension to General Ledger, amounts on the Inventory Interim account will be out of balance when reported per dimension.\\Do you want to keep the changed dimension?';
        Text050: Label 'Cancelled.';
        Text051: Label 'must have the same sign as the receipt';
        Text052: Label 'The quantity that you are trying to invoice is greater than the quantity in receipt %1.';
        Text053: Label 'must have the same sign as the return shipment';
        Text054: Label 'The quantity that you are trying to invoice is greater than the quantity in return shipment %1.';
        PurchSetupRead: Boolean;
        CannotFindDescErr: Label 'Cannot find %1 with Description %2.\\Make sure to use the correct type.', Comment = '%1 = Type caption %2 = Description';
        CommentLbl: Label 'Comment';
        LineDiscountPctErr: Label 'The value in the Line Discount % field must be between 0 and 100.';
        PurchasingBlockedErr: Label 'You cannot purchase item %1 because the Purchasing Blocked check box is selected on the item card.', Comment = '%1 = Item Number';
        CannotChangePrepaidServiceChargeErr: Label 'You cannot change the line because it will affect service charges that are already invoiced as part of a prepayment.';
        LineInvoiceDiscountAmountResetTok: Label 'The value in the Inv. Discount Amount field in %1 has been cleared.', Comment = '%1 - Record ID';
        BlockedItemNotificationMsg: Label 'Item %1 is blocked, but it is allowed on this type of document.', Comment = '%1 is Item No.';
        CannotAllowInvDiscountErr: Label 'The value of the %1 field is not valid when the VAT Calculation Type field is set to "Full VAT".', Comment = '%1 is the name of not valid field';

    procedure InitOutstanding()
    begin
        if IsCreditDocType then begin
            "Outstanding Quantity" := Quantity - "Return Qty. Shipped";
            "Outstanding Qty. (Base)" := "Quantity (Base)" - "Return Qty. Shipped (Base)";
            "Return Qty. Shipped Not Invd." := "Return Qty. Shipped" - "Quantity Invoiced";
            "Ret. Qty. Shpd Not Invd.(Base)" := "Return Qty. Shipped (Base)" - "Qty. Invoiced (Base)";
        end else begin
            "Outstanding Quantity" := Quantity - "Quantity Received";
            "Outstanding Qty. (Base)" := "Quantity (Base)" - "Qty. Received (Base)";
            "Qty. Rcd. Not Invoiced" := "Quantity Received" - "Quantity Invoiced";
            "Qty. Rcd. Not Invoiced (Base)" := "Qty. Received (Base)" - "Qty. Invoiced (Base)";
        end;

        OnAfterInitOutstandingQty(Rec);
        "Completely Received" := (Quantity <> 0) and ("Outstanding Quantity" = 0);
        InitOutstandingAmount;
    end;

    procedure InitOutstandingAmount()
    var
        AmountInclVAT: Decimal;
    begin
        if Quantity = 0 then begin
            "Outstanding Amount" := 0;
            "Outstanding Amount (LCY)" := 0;
            "Outstanding Amt. Ex. VAT (LCY)" := 0;
            "Amt. Rcd. Not Invoiced" := 0;
            "Amt. Rcd. Not Invoiced (LCY)" := 0;
            "Return Shpd. Not Invd." := 0;
            "Return Shpd. Not Invd. (LCY)" := 0;
        end else begin
            GetPurchHeader;
            AmountInclVAT := "Amount Including VAT";
            Validate(
              "Outstanding Amount",
              Round(
                AmountInclVAT * "Outstanding Quantity" / Quantity,
                Currency."Amount Rounding Precision"));
            if IsCreditDocType then
                Validate(
                  "Return Shpd. Not Invd.",
                  Round(
                    AmountInclVAT * "Return Qty. Shipped Not Invd." / Quantity,
                    Currency."Amount Rounding Precision"))
            else
                Validate(
                  "Amt. Rcd. Not Invoiced",
                  Round(
                    AmountInclVAT * "Qty. Rcd. Not Invoiced" / Quantity,
                    Currency."Amount Rounding Precision"));
        end;

        OnAfterInitOutstandingAmount(Rec, xRec, PurchHeader, Currency);
    end;

    procedure InitQtyToReceive()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitQtyToReceive(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        GetPurchSetup;
        if (PurchSetup."Default Qty. to Receive" = PurchSetup."Default Qty. to Receive"::Remainder) or
           ("Document Type" = "Document Type"::Invoice)
        then begin
            "Qty. to Receive" := "Outstanding Quantity";
            "Qty. to Receive (Base)" := "Outstanding Qty. (Base)";
        end else
            if "Qty. to Receive" <> 0 then
                "Qty. to Receive (Base)" :=
                    UOMMgt.CalcBaseQty("No.", "Variant Code", "Unit of Measure Code", "Qty. to Receive", "Qty. per Unit of Measure");

        OnAfterInitQtyToReceive(Rec, CurrFieldNo);

        InitQtyToInvoice;
    end;

    procedure InitQtyToShip()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitQtyToShip(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        GetPurchSetup;
        if (PurchSetup."Default Qty. to Receive" = PurchSetup."Default Qty. to Receive"::Remainder) or
           ("Document Type" = "Document Type"::"Credit Memo")
        then begin
            "Return Qty. to Ship" := "Outstanding Quantity";
            "Return Qty. to Ship (Base)" := "Outstanding Qty. (Base)";
        end else
            if "Return Qty. to Ship" <> 0 then
                "Return Qty. to Ship (Base)" :=
                    UOMMgt.CalcBaseQty("No.", "Variant Code", "Unit of Measure Code", "Return Qty. to Ship", "Qty. per Unit of Measure");

        OnAfterInitQtyToShip(Rec, CurrFieldNo);

        InitQtyToInvoice;
    end;

    procedure InitQtyToInvoice()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitQtyToInvoice(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        "Qty. to Invoice" := MaxQtyToInvoice;
        "Qty. to Invoice (Base)" := MaxQtyToInvoiceBase;
        "VAT Difference" := 0;

        OnBeforeCalcInvDiscToInvoice(Rec, CurrFieldNo);
        CalcInvDiscToInvoice;
        if PurchHeader."Document Type" <> PurchHeader."Document Type"::Invoice then
            CalcPrepaymentToDeduct;

        OnAfterInitQtyToInvoice(Rec, CurrFieldNo);
    end;

    local procedure InitItemAppl()
    begin
        "Appl.-to Item Entry" := 0;
    end;

    local procedure InitHeaderDefaults(PurchHeader: Record "Purchase Header")
    begin
        CheckBuyFromVendorNo(PurchHeader);

        "Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";
        "Currency Code" := PurchHeader."Currency Code";
        "Expected Receipt Date" := PurchHeader."Expected Receipt Date";
        "Shortcut Dimension 1 Code" := PurchHeader."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := PurchHeader."Shortcut Dimension 2 Code";
        if not IsNonInventoriableItem then
            "Location Code" := PurchHeader."Location Code";
        "Transaction Type" := PurchHeader."Transaction Type";
        "Transport Method" := PurchHeader."Transport Method";
        "Pay-to Vendor No." := PurchHeader."Pay-to Vendor No.";
        "Price Calculation Method" := PurchHeader."Price Calculation Method";
        "Gen. Bus. Posting Group" := PurchHeader."Gen. Bus. Posting Group";
        "VAT Bus. Posting Group" := PurchHeader."VAT Bus. Posting Group";
        "Entry Point" := PurchHeader."Entry Point";
        Area := PurchHeader.Area;
        "Transaction Specification" := PurchHeader."Transaction Specification";
        "Tax Area Code" := PurchHeader."Tax Area Code";
        "Tax Liable" := PurchHeader."Tax Liable";
        if not "System-Created Entry" and ("Document Type" = "Document Type"::Order) and HasTypeToFillMandatoryFields or
           IsServiceCharge
        then
            "Prepayment %" := PurchHeader."Prepayment %";
        "Prepayment Tax Area Code" := PurchHeader."Tax Area Code";
        "Prepayment Tax Liable" := PurchHeader."Tax Liable";
        "Responsibility Center" := PurchHeader."Responsibility Center";
        "Requested Receipt Date" := PurchHeader."Requested Receipt Date";
        "Promised Receipt Date" := PurchHeader."Promised Receipt Date";
        "Inbound Whse. Handling Time" := PurchHeader."Inbound Whse. Handling Time";
        "Order Date" := PurchHeader."Order Date";

        OnAfterInitHeaderDefaults(Rec, PurchHeader);
    end;

    procedure MaxQtyToInvoice(): Decimal
    var
        MaxQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMaxQtyToInvoice(Rec, MaxQty, IsHandled);
        if IsHandled then
            exit(MaxQty);

        if "Prepayment Line" then
            exit(1);

        if IsCreditDocType then
            exit("Return Qty. Shipped" + "Return Qty. to Ship" - "Quantity Invoiced");

        exit("Quantity Received" + "Qty. to Receive" - "Quantity Invoiced");
    end;

    procedure MaxQtyToInvoiceBase(): Decimal
    var
        MaxQtyBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMaxQtyToInvoiceBase(Rec, MaxQtyBase, IsHandled);
        if IsHandled then
            exit(MaxQtyBase);

        if IsCreditDocType then
            exit("Return Qty. Shipped (Base)" + "Return Qty. to Ship (Base)" - "Qty. Invoiced (Base)");

        exit("Qty. Received (Base)" + "Qty. to Receive (Base)" - "Qty. Invoiced (Base)");
    end;

    procedure CalcInvDiscToInvoice()
    var
        OldInvDiscAmtToInv: Decimal;
    begin
        GetPurchHeader;
        OldInvDiscAmtToInv := "Inv. Disc. Amount to Invoice";
        if Quantity = 0 then
            Validate("Inv. Disc. Amount to Invoice", 0)
        else
            Validate(
              "Inv. Disc. Amount to Invoice",
              Round(
                "Inv. Discount Amount" * "Qty. to Invoice" / Quantity,
                Currency."Amount Rounding Precision"));

        if OldInvDiscAmtToInv <> "Inv. Disc. Amount to Invoice" then begin
            "Amount Including VAT" := "Amount Including VAT" - "VAT Difference";
            "VAT Difference" := 0;
        end;
        NotifyOnMissingSetup(FieldNo("Inv. Discount Amount"));
    end;

    procedure CalcLineAmount() LineAmount: Decimal
    begin
        LineAmount := "Line Amount" - "Inv. Discount Amount";

        OnAfterCalcLineAmount(Rec, LineAmount);
    end;

    local procedure CopyFromStandardText()
    var
        StandardText: Record "Standard Text";
    begin
        "Tax Area Code" := '';
        "Tax Liable" := false;
        StandardText.Get("No.");
        Description := StandardText.Description;
        "Allow Item Charge Assignment" := false;
        OnAfterAssignStdTxtValues(Rec, StandardText);
    end;

    local procedure CopyFromGLAccount()
    begin
        GLAcc.Get("No.");
        GLAcc.CheckGLAcc;
        if not "System-Created Entry" then
            GLAcc.TestField("Direct Posting", true);
        Description := GLAcc.Name;
        "Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
        "Tax Group Code" := GLAcc."Tax Group Code";
        "Allow Invoice Disc." := false;
        "Allow Item Charge Assignment" := false;
        InitDeferralCode;
        OnAfterAssignGLAccountValues(Rec, GLAcc);
    end;

    local procedure CopyFromItem()
    var
        Item: Record Item;
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
    begin
        GetItem(Item);
        GetGLSetup;
        OnBeforeCopyFromItem(Rec, Item);
        Item.TestField(Blocked, false);
        Item.TestField("Gen. Prod. Posting Group");
        if Item."Purchasing Blocked" then
            if IsCreditDocType then
                SendBlockedItemNotification
            else
                Error(PurchasingBlockedErr, Item."No.");
        if Item.Type = Item.Type::Inventory then begin
            Item.TestField("Inventory Posting Group");
            "Posting Group" := Item."Inventory Posting Group";
        end;

        OnCopyFromItemOnAfterCheck(Rec, Item);

        Description := Item.Description;
        "Description 2" := Item."Description 2";
        "Unit Price (LCY)" := Item."Unit Price";
        "Units per Parcel" := Item."Units per Parcel";
        "Indirect Cost %" := Item."Indirect Cost %";
        "Overhead Rate" := Item."Overhead Rate";
        "Allow Invoice Disc." := Item."Allow Invoice Disc.";
        "Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := Item."VAT Prod. Posting Group";
        "Tax Group Code" := Item."Tax Group Code";
        Nonstock := Item."Created From Nonstock Item";
        "Item Category Code" := Item."Item Category Code";
        "Allow Item Charge Assignment" := true;
        PrepaymentMgt.SetPurchPrepaymentPct(Rec, PurchHeader."Posting Date");
        if IsInventoriableItem then
            PostingSetupMgt.CheckInvtPostingSetupInventoryAccount("Location Code", "Posting Group");

        if Item."Price Includes VAT" then begin
            if not VATPostingSetup.Get(Item."VAT Bus. Posting Gr. (Price)", Item."VAT Prod. Posting Group") then
                VATPostingSetup.Init();
            case VATPostingSetup."VAT Calculation Type" of
                VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT":
                    VATPostingSetup."VAT %" := 0;
                VATPostingSetup."VAT Calculation Type"::"Sales Tax":
                    Error(
                      Text002,
                      VATPostingSetup.FieldCaption("VAT Calculation Type"),
                      VATPostingSetup."VAT Calculation Type");
            end;
            "Unit Price (LCY)" :=
              Round("Unit Price (LCY)" / (1 + VATPostingSetup."VAT %" / 100),
                GLSetup."Unit-Amount Rounding Precision");
        end;

        if PurchHeader."Language Code" <> '' then
            GetItemTranslation;

        "Unit of Measure Code" := Item."Purch. Unit of Measure";
        InitDeferralCode;
        OnAfterAssignItemValues(Rec, Item, CurrFieldNo);
    end;

    local procedure CopyFromFixedAsset()
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.Get("No.");
        FixedAsset.TestField(Inactive, false);
        FixedAsset.TestField(Blocked, false);
        GetFAPostingGroup;
        Description := FixedAsset.Description;
        "Description 2" := FixedAsset."Description 2";
        "Allow Invoice Disc." := false;
        "Allow Item Charge Assignment" := false;
        OnAfterAssignFixedAssetValues(Rec, FixedAsset);
    end;

    local procedure CopyFromItemCharge()
    begin
        ItemCharge.Get("No.");
        Description := ItemCharge.Description;
        "Gen. Prod. Posting Group" := ItemCharge."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := ItemCharge."VAT Prod. Posting Group";
        "Tax Group Code" := ItemCharge."Tax Group Code";
        "Allow Invoice Disc." := false;
        "Allow Item Charge Assignment" := false;
        "Indirect Cost %" := 0;
        "Overhead Rate" := 0;
        OnAfterAssignItemChargeValues(Rec, ItemCharge);
    end;

    local procedure SelectItemEntry()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        TestField("Prod. Order No.", '');
        ItemLedgEntry.SetCurrentKey("Item No.", Open);
        ItemLedgEntry.SetRange("Item No.", "No.");
        ItemLedgEntry.SetRange(Open, true);
        ItemLedgEntry.SetRange(Positive, true);
        if "Location Code" <> '' then
            ItemLedgEntry.SetRange("Location Code", "Location Code");
        ItemLedgEntry.SetRange("Variant Code", "Variant Code");

        if PAGE.RunModal(PAGE::"Item Ledger Entries", ItemLedgEntry) = ACTION::LookupOK then
            Validate("Appl.-to Item Entry", ItemLedgEntry."Entry No.");
    end;

    procedure SetPurchHeader(NewPurchHeader: Record "Purchase Header")
    begin
        PurchHeader := NewPurchHeader;

        if PurchHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision
        else begin
            PurchHeader.TestField("Currency Factor");
            Currency.Get(PurchHeader."Currency Code");
            Currency.TestField("Amount Rounding Precision");
        end;
    end;

    procedure GetPurchHeader()
    begin
        GetPurchHeader(PurchHeader, Currency);
    end;

    procedure GetPurchHeader(var OutPurchHeader: Record "Purchase Header"; OutCurrency: Record Currency)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPurchHeader(Rec, PurchHeader, IsHandled, Currency);
        if IsHandled then
            exit;

        TestField("Document No.");
        if ("Document Type" <> PurchHeader."Document Type") or ("Document No." <> PurchHeader."No.") then begin
            PurchHeader.Get("Document Type", "Document No.");
            if PurchHeader."Currency Code" = '' then
                Currency.InitRoundingPrecision
            else begin
                PurchHeader.TestField("Currency Factor");
                Currency.Get(PurchHeader."Currency Code");
                Currency.TestField("Amount Rounding Precision");
            end;
        end;

        OnAfterGetPurchHeader(Rec, PurchHeader, Currency);
        OutPurchHeader := PurchHeader;
        OutCurrency := Currency;
    end;

    local procedure GetItem(var Item: Record Item)
    begin
        TestField("No.");
        Item.Get("No.");

        OnAfterGetItem(Item, Rec);
    end;

    procedure GetRemainingQty(var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        RemainingQty := "Outstanding Quantity" - Abs("Reserved Quantity");
        RemainingQtyBase := "Outstanding Qty. (Base)" - Abs("Reserved Qty. (Base)");
    end;

    procedure GetReservationQty(var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal): Decimal
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        if "Document Type" = "Document Type"::"Return Order" then begin
            "Reserved Quantity" := -"Reserved Quantity";
            "Reserved Qty. (Base)" := -"Reserved Qty. (Base)";
        end;
        QtyReserved := "Reserved Quantity";
        QtyReservedBase := "Reserved Qty. (Base)";
        QtyToReserve := "Outstanding Quantity";
        QtyToReserveBase := "Outstanding Qty. (Base)";
        exit("Qty. per Unit of Measure");
    end;

    procedure GetSourceCaption(): Text
    begin
        exit(StrSubstNo('%1 %2 %3', "Document Type", "Document No.", "No."));
    end;

    procedure SetReservationEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSource(DATABASE::"Purchase Line", "Document Type", "Document No.", "Line No.", '', 0);
        ReservEntry.SetItemData("No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        if Type <> Type::Item then
            ReservEntry."Item No." := '';
        ReservEntry."Expected Receipt Date" := "Expected Receipt Date";
        ReservEntry."Shipment Date" := "Expected Receipt Date";
        ReservEntry."Planning Flexibility" := "Planning Flexibility";
    end;

    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter(DATABASE::"Purchase Line", "Document Type", "Document No.", "Line No.", false);
        ReservEntry.SetSourceFilter('', 0);

        OnAfterSetReservationFilters(ReservEntry, Rec);
    end;

    procedure ReservEntryExist(): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(false);
        SetReservationFilters(ReservEntry);
        exit(not ReservEntry.IsEmpty);
    end;

    local procedure IsPriceCalcCalledByField(CurrPriceFieldNo: Integer): Boolean;
    begin
        exit(FieldCausedPriceCalculation = CurrPriceFieldNo);
    end;

    local procedure PlanPriceCalcByField(CurrPriceFieldNo: Integer)
    begin
        if FieldCausedPriceCalculation = 0 then
            FieldCausedPriceCalculation := CurrPriceFieldNo;
    end;

    local procedure ClearFieldCausedPriceCalculation()
    begin
        FieldCausedPriceCalculation := 0;
    end;

    procedure UpdateDirectUnitCost(CalledByFieldNo: Integer)
    begin
        ClearFieldCausedPriceCalculation();
        PlanPriceCalcByField(CalledByFieldNo);
        UpdateDirectUnitCostByField(CalledByFieldNo);
    end;

    local procedure UpdateDirectUnitCostByField(CalledByFieldNo: Integer)
    var
        IsHandled: Boolean;
        PriceCalculation: Interface "Price Calculation";
    begin
        if not IsPriceCalcCalledByField(CalledByFieldNo) then
            exit;

        IsHandled := false;
        OnBeforeUpdateDirectUnitCost(Rec, xRec, CalledByFieldNo, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if (CurrFieldNo <> 0) and ("Prod. Order No." <> '') then
            UpdateAmounts;

        if ((CalledByFieldNo <> CurrFieldNo) and (CurrFieldNo <> 0)) or
           ("Prod. Order No." <> '')
        then
            exit;

        if Type in [Type::Item, Type::Resource] then begin
            GetPurchHeader;
            IsHandled := false;
            OnUpdateDirectUnitCostOnBeforeFindPrice(PurchHeader, Rec, CalledByFieldNo, CurrFieldNo, IsHandled);
            if not IsHandled then begin
                GetPriceCalculationHandler(PurchHeader, PriceCalculation);
                PriceCalculation.ApplyPrice(CalledByFieldNo);
                if not ("Copied From Posted Doc." and IsCreditDocType) then
                    PriceCalculation.ApplyDiscount();
                GetLineWithPrice(PriceCalculation);
            end;
            Validate("Direct Unit Cost");
        end;

        if Type = Type::Item then
            if CalledByFieldNo in [FieldNo("No."), FieldNo("Variant Code"), FieldNo("Location Code")] then
                UpdateItemReference;

        ClearFieldCausedPriceCalculation();
        OnAfterUpdateDirectUnitCost(Rec, xRec, CalledByFieldNo, CurrFieldNo);
    end;

    local procedure GetLineWithPrice(var PriceCalculation: Interface "Price Calculation")
    var
        Line: Variant;
    begin
        PriceCalculation.GetLine(Line);
        Rec := Line;
    end;

    local procedure GetPriceCalculationHandler(PurchaseHeader: Record "Purchase Header"; var PriceCalculation: Interface "Price Calculation")
    var
        PriceCalculationMgt: codeunit "Price Calculation Mgt.";
        PurchaseLinePrice: Codeunit "Purchase Line - Price";
        PriceType: Enum "Price Type";
    begin
        if (PurchaseHeader."No." = '') and ("Document No." <> '') then
            PurchaseHeader.Get("Document Type", "Document No.");
        PurchaseLinePrice.SetLine(PriceType::Purchase, PurchaseHeader, Rec);
        PriceCalculationMgt.GetHandler(PurchaseLinePrice, PriceCalculation);
    end;

    procedure CountDiscount(ShowAll: Boolean): Integer;
    var
        PriceCalculation: Interface "Price Calculation";
    begin
        GetPriceCalculationHandler(PurchHeader, PriceCalculation);
        exit(PriceCalculation.CountDiscount(ShowAll));
    end;

    procedure CountPrice(ShowAll: Boolean): Integer;
    var
        PriceCalculation: Interface "Price Calculation";
    begin
        GetPriceCalculationHandler(PurchHeader, PriceCalculation);
        exit(PriceCalculation.CountPrice(ShowAll));
    end;

    procedure DiscountExists(ShowAll: Boolean): Boolean;
    var
        PriceCalculation: Interface "Price Calculation";
    begin
        GetPriceCalculationHandler(PurchHeader, PriceCalculation);
        exit(PriceCalculation.IsDiscountExists(ShowAll));
    end;

    procedure PriceExists(ShowAll: Boolean): Boolean;
    var
        PriceCalculation: Interface "Price Calculation";
    begin
        GetPriceCalculationHandler(PurchHeader, PriceCalculation);
        exit(PriceCalculation.IsPriceExists(ShowAll));
    end;

    procedure PickDiscount()
    var
        PriceCalculation: Interface "Price Calculation";
    begin
        GetPriceCalculationHandler(PurchHeader, PriceCalculation);
        PriceCalculation.PickDiscount();
        GetLineWithPrice(PriceCalculation);
    end;

    procedure PickPrice()
    var
        PriceCalculation: Interface "Price Calculation";
    begin
        GetPriceCalculationHandler(PurchHeader, PriceCalculation);
        PriceCalculation.PickPrice();
        GetLineWithPrice(PriceCalculation);
    end;

    procedure UpdateUnitCost()
    var
        Item: Record Item;
        DiscountAmountPerQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateUnitCost(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        GetPurchHeader;
        GetGLSetup;
        if Quantity = 0 then
            DiscountAmountPerQty := 0
        else
            DiscountAmountPerQty :=
              Round(("Line Discount Amount" + "Inv. Discount Amount") / Quantity,
                GLSetup."Unit-Amount Rounding Precision");

        if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then
            "Unit Cost" := 0
        else
            if PurchHeader."Prices Including VAT" then
                "Unit Cost" :=
                  ("Direct Unit Cost" - DiscountAmountPerQty) * (1 + "Indirect Cost %" / 100) / (1 + "VAT %" / 100) +
                  GetOverheadRateFCY - "VAT Difference"
            else
                "Unit Cost" :=
                  ("Direct Unit Cost" - DiscountAmountPerQty) * (1 + "Indirect Cost %" / 100) +
                  GetOverheadRateFCY;

        OnUpdateUnitCostOnBeforeUpdateUnitCostLCY(Rec, xRec, PurchHeader, CurrFieldNo, Item, SKU, Currency, GLSetup);

        if PurchHeader."Currency Code" <> '' then begin
            PurchHeader.TestField("Currency Factor");
            "Unit Cost (LCY)" :=
              CurrExchRate.ExchangeAmtFCYToLCY(
                GetDate, "Currency Code",
                "Unit Cost", PurchHeader."Currency Factor");
        end else
            "Unit Cost (LCY)" := "Unit Cost";

        if (Type = Type::Item) and ("Prod. Order No." = '') then begin
            GetItem(Item);
            if Item."Costing Method" = Item."Costing Method"::Standard then begin
                if GetSKU then
                    "Unit Cost (LCY)" := SKU."Unit Cost" * "Qty. per Unit of Measure"
                else
                    "Unit Cost (LCY)" := Item."Unit Cost" * "Qty. per Unit of Measure";
            end;
        end;

        "Unit Cost (LCY)" := Round("Unit Cost (LCY)", GLSetup."Unit-Amount Rounding Precision");
        if PurchHeader."Currency Code" <> '' then
            Currency.TestField("Unit-Amount Rounding Precision");
        "Unit Cost" := Round("Unit Cost", Currency."Unit-Amount Rounding Precision");

        OnAfterUpdateUnitCost(Rec, xRec, PurchHeader, Item, SKU, Currency, GLSetup);

        UpdateSalesCost;

        if JobTaskIsSet and not UpdateFromVAT and not "Prepayment Line" then begin
            CreateTempJobJnlLine(false);
            TempJobJnlLine.Validate("Unit Cost (LCY)", "Unit Cost (LCY)");
            UpdateJobPrices;
        end;
    end;

    procedure UpdateAmounts()
    var
        VATBaseAmount: Decimal;
        LineAmountChanged: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAmounts(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if Type = Type::" " then
            exit;

        GetPurchHeader;

        VATBaseAmount := "VAT Base Amount";
        "Recalculate Invoice Disc." := true;

        if "Line Amount" <> xRec."Line Amount" then begin
            "VAT Difference" := 0;
            LineAmountChanged := true;
        end;
        if "Line Amount" <> Round(Quantity * "Direct Unit Cost", Currency."Amount Rounding Precision") - "Line Discount Amount" then begin
            "Line Amount" :=
              Round(Quantity * "Direct Unit Cost", Currency."Amount Rounding Precision") - "Line Discount Amount";
            "VAT Difference" := 0;
            LineAmountChanged := true;
        end;

        if not "Prepayment Line" then
            UpdatePrepmtAmounts();

        OnAfterUpdateAmounts(Rec, xRec, CurrFieldNo);

        UpdateVATAmounts;
        if VATBaseAmount <> "VAT Base Amount" then
            LineAmountChanged := true;

        if LineAmountChanged then begin
            UpdateDeferralAmounts;
            LineAmountChanged := false;
        end;

        InitOutstandingAmount;

        if Type = Type::"Charge (Item)" then
            UpdateItemChargeAssgnt;

        CalcPrepaymentToDeduct;

        OnAfterUpdateAmountsDone(Rec, xRec, CurrFieldNo);
    end;

    procedure UpdateVATAmounts()
    var
        PurchLine2: Record "Purchase Line";
        TotalLineAmount: Decimal;
        TotalInvDiscAmount: Decimal;
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        TotalQuantityBase: Decimal;
    begin
        OnBeforeUpdateVATAmounts(Rec);

        GetPurchHeader;
        PurchLine2.SetRange("Document Type", "Document Type");
        PurchLine2.SetRange("Document No.", "Document No.");
        PurchLine2.SetFilter("Line No.", '<>%1', "Line No.");
        PurchLine2.SetRange("VAT Identifier", "VAT Identifier");
        PurchLine2.SetRange("Tax Group Code", "Tax Group Code");
        PurchLine2.SetRange("Tax Area Code", "Tax Area Code");

        if "Line Amount" = "Inv. Discount Amount" then begin
            Amount := 0;
            "VAT Base Amount" := 0;
            "Amount Including VAT" := 0;
            if (Quantity = 0) and (xRec.Quantity <> 0) and (xRec.Amount <> 0) then begin
                if "Line No." <> 0 then
                    Modify;
                PurchLine2.SetFilter(Amount, '<>0');
                if PurchLine2.Find('<>') then begin
                    PurchLine2.ValidateLineDiscountPercent(false);
                    PurchLine2.Modify();
                end;
            end;
        end else begin
            TotalLineAmount := 0;
            TotalInvDiscAmount := 0;
            TotalAmount := 0;
            TotalAmountInclVAT := 0;
            TotalQuantityBase := 0;
            if ("VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax") or
               (("VAT Calculation Type" in
                 ["VAT Calculation Type"::"Normal VAT", "VAT Calculation Type"::"Reverse Charge VAT"]) and ("VAT %" <> 0))
            then begin
                PurchLine2.SetFilter("VAT %", '<>0');
                if not PurchLine2.IsEmpty then begin
                    PurchLine2.CalcSums("Line Amount", "Inv. Discount Amount", Amount, "Amount Including VAT", "Quantity (Base)");
                    TotalLineAmount := PurchLine2."Line Amount";
                    TotalInvDiscAmount := PurchLine2."Inv. Discount Amount";
                    TotalAmount := PurchLine2.Amount;
                    TotalAmountInclVAT := PurchLine2."Amount Including VAT";
                    TotalQuantityBase := PurchLine2."Quantity (Base)";
                    OnAfterUpdateTotalAmounts(Rec, PurchLine2, TotalAmount, TotalAmountInclVAT, TotalLineAmount, TotalInvDiscAmount);
                end;
            end;

            if PurchHeader."Prices Including VAT" then
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            Amount :=
                              Round(
                                (TotalLineAmount - TotalInvDiscAmount + CalcLineAmount) / (1 + "VAT %" / 100),
                                Currency."Amount Rounding Precision") -
                              TotalAmount;
                            "VAT Base Amount" :=
                              Round(
                                Amount * (1 - PurchHeader."VAT Base Discount %" / 100),
                                Currency."Amount Rounding Precision");
                            "Amount Including VAT" :=
                              TotalLineAmount + "Line Amount" -
                              Round(
                                (TotalAmount + Amount) * (PurchHeader."VAT Base Discount %" / 100) * "VAT %" / 100,
                                Currency."Amount Rounding Precision", Currency.VATRoundingDirection) -
                              TotalAmountInclVAT - TotalInvDiscAmount - "Inv. Discount Amount";
                        end;
                    "VAT Calculation Type"::"Full VAT":
                        begin
                            Amount := 0;
                            "VAT Base Amount" := 0;
                            "Amount Including VAT" := ROUND(CalcLineAmount(), Currency."Amount Rounding Precision");
                        end;
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            PurchHeader.TestField("VAT Base Discount %", 0);
                            "Amount Including VAT" :=
                              Round(CalcLineAmount, Currency."Amount Rounding Precision");
                            if "Use Tax" then
                                Amount := "Amount Including VAT"
                            else
                                Amount :=
                                  Round(
                                    SalesTaxCalculate.ReverseCalculateTax(
                                      "Tax Area Code", "Tax Group Code", "Tax Liable", PurchHeader."Posting Date",
                                      TotalAmountInclVAT + "Amount Including VAT", TotalQuantityBase + "Quantity (Base)",
                                      PurchHeader."Currency Factor"),
                                    Currency."Amount Rounding Precision") -
                                  TotalAmount;
                            OnAfterSalesTaxCalculateReverse(Rec, PurchHeader, Currency);
                            "VAT Base Amount" := Amount;
                            if "VAT Base Amount" <> 0 then
                                "VAT %" :=
                                  Round(100 * ("Amount Including VAT" - "VAT Base Amount") / "VAT Base Amount", 0.00001)
                            else
                                "VAT %" := 0;
                        end;
                end
            else
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            Amount := Round(CalcLineAmount, Currency."Amount Rounding Precision");
                            "VAT Base Amount" :=
                              Round(Amount * (1 - PurchHeader."VAT Base Discount %" / 100), Currency."Amount Rounding Precision");
                            "Amount Including VAT" :=
                              TotalAmount + Amount +
                              Round(
                                (TotalAmount + Amount) * (1 - PurchHeader."VAT Base Discount %" / 100) * "VAT %" / 100,
                                Currency."Amount Rounding Precision", Currency.VATRoundingDirection) -
                              TotalAmountInclVAT;
                        end;
                    "VAT Calculation Type"::"Full VAT":
                        begin
                            Amount := 0;
                            "VAT Base Amount" := 0;
                            "Amount Including VAT" := CalcLineAmount;
                        end;
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            Amount := Round(CalcLineAmount, Currency."Amount Rounding Precision");
                            "VAT Base Amount" := Amount;
                            if "Use Tax" then
                                "Amount Including VAT" := Amount
                            else
                                "Amount Including VAT" :=
                                  TotalAmount + Amount +
                                  Round(
                                    SalesTaxCalculate.CalculateTax(
                                      "Tax Area Code", "Tax Group Code", "Tax Liable", PurchHeader."Posting Date",
                                      TotalAmount + Amount, TotalQuantityBase + "Quantity (Base)",
                                      PurchHeader."Currency Factor"),
                                    Currency."Amount Rounding Precision") -
                                  TotalAmountInclVAT;
                            OnAfterSalesTaxCalculate(Rec, PurchHeader, Currency);
                            if "VAT Base Amount" <> 0 then
                                "VAT %" :=
                                  Round(100 * ("Amount Including VAT" - "VAT Base Amount") / "VAT Base Amount", 0.00001)
                            else
                                "VAT %" := 0;
                        end;
                end;
        end;

        OnAfterUpdateVATAmounts(Rec);
    end;

    procedure UpdatePrepmtSetupFields()
    var
        GenPostingSetup: Record "General Posting Setup";
        GLAcc: Record "G/L Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePrepmtSetupFields(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Prepayment %" <> 0) and HasTypeToFillMandatoryFields then begin
            TestField("Document Type", "Document Type"::Order);
            TestField("No.");
            GenPostingSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
            if GenPostingSetup."Purch. Prepayments Account" <> '' then begin
                GLAcc.Get(GenPostingSetup."Purch. Prepayments Account");
                VATPostingSetup.Get("VAT Bus. Posting Group", GLAcc."VAT Prod. Posting Group");
                VATPostingSetup.TestField("VAT Calculation Type", "VAT Calculation Type");
            end else
                Clear(VATPostingSetup);
            "Prepayment VAT %" := VATPostingSetup."VAT %";
            "Prepmt. VAT Calc. Type" := VATPostingSetup."VAT Calculation Type";
            "Prepayment VAT Identifier" := VATPostingSetup."VAT Identifier";
            if "Prepmt. VAT Calc. Type" in
               ["Prepmt. VAT Calc. Type"::"Reverse Charge VAT", "Prepmt. VAT Calc. Type"::"Sales Tax"]
            then
                "Prepayment VAT %" := 0;
            "Prepayment Tax Group Code" := GLAcc."Tax Group Code";
        end;
    end;

    local procedure UpdateSalesCost()
    var
        SalesOrderLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        case true of
            "Sales Order Line No." <> 0:
                // Drop Shipment
                SalesOrderLine.Get(SalesOrderLine."Document Type"::Order, "Sales Order No.", "Sales Order Line No.");
            "Special Order Sales Line No." <> 0:
                // Special Order
                begin
                    if not
                       SalesOrderLine.Get(SalesOrderLine."Document Type"::Order, "Special Order Sales No.", "Special Order Sales Line No.")
                    then
                        exit;
                end;
            else
                exit;
        end;

        IsHandled := false;
        OnBeforeUpdateSalesCost(Rec, SalesOrderLine, IsHandled);
        if IsHandled then
            exit;

        SalesOrderLine."Unit Cost (LCY)" := "Unit Cost (LCY)" * SalesOrderLine."Qty. per Unit of Measure" / "Qty. per Unit of Measure";
        SalesOrderLine."Unit Cost" := "Unit Cost" * SalesOrderLine."Qty. per Unit of Measure" / "Qty. per Unit of Measure";
        SalesOrderLine.Validate("Unit Cost (LCY)");
        SalesOrderLine.Modify();

        OnAfterUpdateSalesCost(Rec, SalesOrderLine);
    end;

    local procedure GetFAPostingGroup()
    var
        LocalGLAcc: Record "G/L Account";
        FAPostingGr: Record "FA Posting Group";
        FADeprBook: Record "FA Depreciation Book";
        FASetup: Record "FA Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetFAPostingGroup(Rec, IsHandled);
        if IsHandled then
            exit;

        if (Type <> Type::"Fixed Asset") or ("No." = '') then
            exit;
        if "Depreciation Book Code" = '' then begin
            FASetup.Get();
            "Depreciation Book Code" := FASetup."Default Depr. Book";
            if not FADeprBook.Get("No.", "Depreciation Book Code") then
                "Depreciation Book Code" := '';
            if "Depreciation Book Code" = '' then
                exit;
        end;
        if "FA Posting Type" = "FA Posting Type"::" " then
            "FA Posting Type" := "FA Posting Type"::"Acquisition Cost";
        FADeprBook.Get("No.", "Depreciation Book Code");
        FADeprBook.TestField("FA Posting Group");
        FAPostingGr.Get(FADeprBook."FA Posting Group");
        case "FA Posting Type" of
            "FA Posting Type"::"Acquisition Cost":
                LocalGLAcc.Get(FAPostingGr.GetAcquisitionCostAccount);
            "FA Posting Type"::Appreciation:
                LocalGLAcc.Get(FAPostingGr.GetAppreciationAccount);
            "FA Posting Type"::Maintenance:
                LocalGLAcc.Get(FAPostingGr.GetMaintenanceExpenseAccount);
        end;
        LocalGLAcc.CheckGLAcc;
        if not ApplicationAreaMgmt.IsSalesTaxEnabled then
            LocalGLAcc.TestField("Gen. Prod. Posting Group");
        "Posting Group" := FADeprBook."FA Posting Group";
        "Gen. Prod. Posting Group" := LocalGLAcc."Gen. Prod. Posting Group";
        "Tax Group Code" := LocalGLAcc."Tax Group Code";
        Validate("VAT Prod. Posting Group", LocalGLAcc."VAT Prod. Posting Group");

        OnAfterGetFAPostingGroup(Rec, LocalGLAcc);
    end;

    procedure UpdateUOMQtyPerStockQty()
    var
        Item: Record Item;
    begin
        GetItem(Item);
        "Unit Cost (LCY)" := Item."Unit Cost" * "Qty. per Unit of Measure";
        "Unit Price (LCY)" := Item."Unit Price" * "Qty. per Unit of Measure";
        GetPurchHeader;
        if PurchHeader."Currency Code" <> '' then
            "Unit Cost" :=
              CurrExchRate.ExchangeAmtLCYToFCY(
                GetDate, PurchHeader."Currency Code",
                "Unit Cost (LCY)", PurchHeader."Currency Factor")
        else
            "Unit Cost" := "Unit Cost (LCY)";
        if "Unit of Measure Code" <> xRec."Unit of Measure Code" then
            PlanPriceCalcByField(FieldNo("Unit of Measure Code"));
        UpdateDirectUnitCostByField(FieldNo("Unit of Measure Code"));
    end;

    procedure SelectMultipleItems()
    var
        ItemListPage: Page "Item List";
        SelectionFilter: Text;
    begin
        if IsCreditDocType then
            SelectionFilter := ItemListPage.SelectActiveItems
        else
            SelectionFilter := ItemListPage.SelectActiveItemsForPurchase;
        if SelectionFilter <> '' then
            AddItems(SelectionFilter);
    end;

    local procedure AddItems(SelectionFilter: Text)
    var
        Item: Record Item;
        PurchLine: Record "Purchase Line";
        LastPurchLine: Record "Purchase Line";
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        OnBeforeAddItems(Rec);

        InitNewLine(PurchLine);
        Item.SetFilter("No.", SelectionFilter);
        if Item.FindSet then
            repeat
                PurchLine.Init();
                PurchLine."Line No." += 10000;
                PurchLine.Validate(Type, Type::Item);
                PurchLine.Validate("No.", Item."No.");
                PurchLine.Insert(true);
                if TransferExtendedText.PurchCheckIfAnyExtText(PurchLine, false) then begin
                    TransferExtendedText.InsertPurchExtTextRetLast(PurchLine, LastPurchLine);
                    PurchLine."Line No." := LastPurchLine."Line No."
                end;
                OnAfterAddItem(PurchLine, LastPurchLine);
            until Item.Next = 0;
    end;

    local procedure InitNewLine(var NewPurchLine: Record "Purchase Line")
    var
        PurchLine: Record "Purchase Line";
    begin
        NewPurchLine.Copy(Rec);
        PurchLine.SetRange("Document Type", NewPurchLine."Document Type");
        PurchLine.SetRange("Document No.", NewPurchLine."Document No.");
        if PurchLine.FindLast then
            NewPurchLine."Line No." := PurchLine."Line No."
        else
            NewPurchLine."Line No." := 0;
    end;

    procedure ShowReservation()
    var
        Reservation: Page Reservation;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowReservation(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField(Type, Type::Item);
        TestField("Prod. Order No.", '');
        TestField("No.");
        Clear(Reservation);
        Reservation.SetReservSource(Rec);
        Reservation.RunModal();
    end;

    procedure ShowReservationEntries(Modal: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowReservationEntries(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField(Type, Type::Item);
        TestField("No.");
        ReservEntry.InitSortingAndFilters(true);
        SetReservationFilters(ReservEntry);
        if Modal then
            PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry)
        else
            PAGE.Run(PAGE::"Reservation Entries", ReservEntry);
    end;

    procedure GetDate(): Date
    begin
        GetPurchHeader;
        if PurchHeader."Posting Date" <> 0D then
            exit(PurchHeader."Posting Date");
        exit(WorkDate);
    end;

    procedure Signed(Value: Decimal): Decimal
    begin
        case "Document Type" of
            "Document Type"::Quote,
          "Document Type"::Order,
          "Document Type"::Invoice,
          "Document Type"::"Blanket Order":
                exit(Value);
            "Document Type"::"Return Order",
          "Document Type"::"Credit Memo":
                exit(-Value);
        end;
    end;

    procedure BlanketOrderLookup()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBlanketOrderLookup(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        PurchLine2.Reset();
        PurchLine2.SetCurrentKey("Document Type", Type, "No.");
        PurchLine2.SetRange("Document Type", "Document Type"::"Blanket Order");
        PurchLine2.SetRange(Type, Type);
        PurchLine2.SetRange("No.", "No.");
        PurchLine2.SetRange("Pay-to Vendor No.", "Pay-to Vendor No.");
        PurchLine2.SetRange("Buy-from Vendor No.", "Buy-from Vendor No.");
        if PAGE.RunModal(PAGE::"Purchase Lines", PurchLine2) = ACTION::LookupOK then begin
            PurchLine2.TestField("Document Type", "Document Type"::"Blanket Order");
            "Blanket Order No." := PurchLine2."Document No.";
            Validate("Blanket Order Line No.", PurchLine2."Line No.");
        end;

        OnAfterBlanketOrderLookup(Rec);
    end;

    procedure BlockDynamicTracking(SetBlock: Boolean)
    begin
        TrackingBlocked := SetBlock;
        ReservePurchLine.Block(SetBlock);
    end;

    procedure ShowDimensions() IsChanged: Boolean
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', "Document Type", "Document No.", "Line No."));
        VerifyItemLineDim;
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        IsChanged := OldDimSetID <> "Dimension Set ID";

        OnAfterShowDimensions(Rec, xRec);
    end;

    procedure OpenItemTrackingLines()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenItemTrackingLines(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField(Type, Type::Item);
        TestField("No.");
        if "Prod. Order No." <> '' then
            Error(Text031, "Prod. Order No.");

        TestField("Quantity (Base)");

        ReservePurchLine.CallItemTracking(Rec);
    end;

    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20]; Type3: Integer; No3: Code[20]; Type4: Integer; No4: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        SourceCodeSetup.Get();
        TableID[1] := Type1;
        No[1] := No1;
        TableID[2] := Type2;
        No[2] := No2;
        TableID[3] := Type3;
        No[3] := No3;
        TableID[4] := Type4;
        No[4] := No4;
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        GetPurchHeader;
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, TableID, No, SourceCodeSetup.Purchases,
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", PurchHeader."Dimension Set ID", DATABASE::Vendor);
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterCreateDim(Rec, CurrFieldNo);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        VerifyItemLineDim;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        ValidateShortcutDimCode(FieldNumber, ShortcutDimCode);
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    local procedure GetSKU(): Boolean
    begin
        TestField("No.");
        if (SKU."Location Code" = "Location Code") and
           (SKU."Item No." = "No.") and
           (SKU."Variant Code" = "Variant Code")
        then
            exit(true);
        if SKU.Get("Location Code", "No.", "Variant Code") then
            exit(true);

        exit(false);
    end;

    procedure ShowItemChargeAssgnt()
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        AssignItemChargePurch: Codeunit "Item Charge Assgnt. (Purch.)";
        ItemChargeAssgnts: Page "Item Charge Assignment (Purch)";
        ItemChargeAssgntLineAmt: Decimal;
        IsHandled: Boolean;
    begin
        Get("Document Type", "Document No.", "Line No.");
        TestField("No.");
        TestField(Quantity);

        if Type <> Type::"Charge (Item)" then
            Error(ItemChargeAssignmentErr);

        GetPurchHeader;
        if PurchHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision
        else
            Currency.Get(PurchHeader."Currency Code");
        if ("Inv. Discount Amount" = 0) and
           ("Line Discount Amount" = 0) and
           (not PurchHeader."Prices Including VAT")
        then
            ItemChargeAssgntLineAmt := "Line Amount"
        else
            if PurchHeader."Prices Including VAT" then
                ItemChargeAssgntLineAmt :=
                  Round(CalcLineAmount / (1 + "VAT %" / 100), Currency."Amount Rounding Precision")
            else
                ItemChargeAssgntLineAmt := CalcLineAmount;

        ItemChargeAssgntPurch.Reset();
        ItemChargeAssgntPurch.SetRange("Document Type", "Document Type");
        ItemChargeAssgntPurch.SetRange("Document No.", "Document No.");
        ItemChargeAssgntPurch.SetRange("Document Line No.", "Line No.");
        ItemChargeAssgntPurch.SetRange("Item Charge No.", "No.");
        if not ItemChargeAssgntPurch.FindLast then begin
            ItemChargeAssgntPurch."Document Type" := "Document Type";
            ItemChargeAssgntPurch."Document No." := "Document No.";
            ItemChargeAssgntPurch."Document Line No." := "Line No.";
            ItemChargeAssgntPurch."Item Charge No." := "No.";
            ItemChargeAssgntPurch."Unit Cost" :=
              Round(ItemChargeAssgntLineAmt / Quantity,
                Currency."Unit-Amount Rounding Precision");
        end;


        IsHandled := false;
        OnShowItemChargeAssgntOnBeforeCalcItemCharge(Rec, ItemChargeAssgntLineAmt, Currency, IsHandled, ItemChargeAssgntPurch);
        if not IsHandled then
            ItemChargeAssgntLineAmt :=
                Round(ItemChargeAssgntLineAmt * ("Qty. to Invoice" / Quantity), Currency."Amount Rounding Precision");

        if IsCreditDocType then
            AssignItemChargePurch.CreateDocChargeAssgnt(ItemChargeAssgntPurch, "Return Shipment No.")
        else
            AssignItemChargePurch.CreateDocChargeAssgnt(ItemChargeAssgntPurch, "Receipt No.");
        Clear(AssignItemChargePurch);
        Commit();

        ItemChargeAssgnts.Initialize(Rec, ItemChargeAssgntLineAmt);
        ItemChargeAssgnts.RunModal;

        CalcFields("Qty. to Assign");
    end;

    procedure UpdateItemChargeAssgnt()
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ShareOfVAT: Decimal;
        TotalQtyToAssign: Decimal;
        TotalAmtToAssign: Decimal;
    begin
        if "Document Type" = "Document Type"::"Blanket Order" then
            exit;

        CalcFields("Qty. Assigned", "Qty. to Assign");
        if Abs("Quantity Invoiced") > Abs(("Qty. Assigned" + "Qty. to Assign")) then
            Error(Text032, FieldCaption("Quantity Invoiced"), FieldCaption("Qty. Assigned"), FieldCaption("Qty. to Assign"));

        ItemChargeAssgntPurch.SetRange("Document Type", "Document Type");
        ItemChargeAssgntPurch.SetRange("Document No.", "Document No.");
        ItemChargeAssgntPurch.SetRange("Document Line No.", "Line No.");
        ItemChargeAssgntPurch.CalcSums("Qty. to Assign");
        TotalQtyToAssign := ItemChargeAssgntPurch."Qty. to Assign";
        if (CurrFieldNo <> 0) and ("Unit Cost" <> xRec."Unit Cost") then begin
            ItemChargeAssgntPurch.SetFilter("Qty. Assigned", '<>0');
            if not ItemChargeAssgntPurch.IsEmpty then
                Error(Text022,
                  FieldCaption("Unit Cost"));
            ItemChargeAssgntPurch.SetRange("Qty. Assigned");
        end;

        if (CurrFieldNo <> 0) and (Quantity <> xRec.Quantity) then begin
            ItemChargeAssgntPurch.SetFilter("Qty. Assigned", '<>0');
            if not ItemChargeAssgntPurch.IsEmpty then
                Error(Text022,
                  FieldCaption(Quantity));
            ItemChargeAssgntPurch.SetRange("Qty. Assigned");
        end;

        if ItemChargeAssgntPurch.FindSet(true) and (Quantity <> 0) then begin
            GetPurchHeader;
            TotalAmtToAssign := CalcTotalAmtToAssign(TotalQtyToAssign);
            repeat
                ShareOfVAT := 1;
                if PurchHeader."Prices Including VAT" then
                    ShareOfVAT := 1 + "VAT %" / 100;
                if ItemChargeAssgntPurch."Unit Cost" <>
                   Round(CalcLineAmount / Quantity / ShareOfVAT, Currency."Unit-Amount Rounding Precision")
                then
                    ItemChargeAssgntPurch."Unit Cost" :=
                      Round(CalcLineAmount / Quantity / ShareOfVAT, Currency."Unit-Amount Rounding Precision");
                if TotalQtyToAssign <> 0 then begin
                    ItemChargeAssgntPurch."Amount to Assign" :=
                      Round(ItemChargeAssgntPurch."Qty. to Assign" / TotalQtyToAssign * TotalAmtToAssign,
                        Currency."Amount Rounding Precision");
                    TotalQtyToAssign -= ItemChargeAssgntPurch."Qty. to Assign";
                    TotalAmtToAssign -= ItemChargeAssgntPurch."Amount to Assign";
                end;
                ItemChargeAssgntPurch.Modify();
            until ItemChargeAssgntPurch.Next = 0;
            CalcFields("Qty. to Assign");
        end;
    end;

    local procedure DeleteItemChargeAssgnt(DocType: Option; DocNo: Code[20]; DocLineNo: Integer)
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. Type", DocType);
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. No.", DocNo);
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. Line No.", DocLineNo);
        if not ItemChargeAssgntPurch.IsEmpty then
            ItemChargeAssgntPurch.DeleteAll(true);

        OnAfterDeleteChargeChargeAssgnt(Rec, xRec, CurrFieldNo);
    end;

    local procedure DeleteChargeChargeAssgnt(DocType: Option; DocNo: Code[20]; DocLineNo: Integer)
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        if DocType <> "Document Type"::"Blanket Order" then
            if "Quantity Invoiced" <> 0 then begin
                CalcFields("Qty. Assigned");
                TestField("Qty. Assigned", "Quantity Invoiced");
            end;

        ItemChargeAssgntPurch.Reset();
        ItemChargeAssgntPurch.SetRange("Document Type", DocType);
        ItemChargeAssgntPurch.SetRange("Document No.", DocNo);
        ItemChargeAssgntPurch.SetRange("Document Line No.", DocLineNo);
        if not ItemChargeAssgntPurch.IsEmpty then
            ItemChargeAssgntPurch.DeleteAll();
    end;

    procedure CheckItemChargeAssgnt()
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. Type", "Document Type");
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. No.", "Document No.");
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. Line No.", "Line No.");
        ItemChargeAssgntPurch.SetRange("Document Type", "Document Type");
        ItemChargeAssgntPurch.SetRange("Document No.", "Document No.");
        if ItemChargeAssgntPurch.FindSet then begin
            TestField("Allow Item Charge Assignment");
            repeat
                ItemChargeAssgntPurch.TestField("Qty. to Assign", 0);
            until ItemChargeAssgntPurch.Next = 0;
        end;
    end;

    local procedure CheckAssosiatedSalesOrder()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAssosiatedSalesOrder(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if "Drop Shipment" then
            Error(Text001, FieldCaption("No."), "Sales Order No.");
        if "Special Order" then
            Error(Text001, FieldCaption("No."), "Special Order Sales No.");
    end;

    local procedure CheckAssosiatedProdOrder()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAssosiatedProdOrder(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if "Prod. Order No." <> '' then
            Error(Text044, FieldCaption(Type), FieldCaption("Prod. Order No."), "Prod. Order No.");
    end;

    procedure GetCaptionClass(FieldNumber: Integer): Text[80]
    var
        PurchLineCaptionClassMgmt: Codeunit "Purch. Line CaptionClass Mgmt";
    begin
        exit(PurchLineCaptionClassMgmt.GetPurchaseLineCaptionClass(Rec, FieldNumber));
    end;

    procedure TestStatusOpen()
    begin
        GetPurchHeader;
        OnBeforeTestStatusOpen(Rec, PurchHeader);

        if StatusCheckSuspended then
            exit;

        if not "System-Created Entry" then
            if HasTypeToFillMandatoryFields then
                PurchHeader.TestField(Status, PurchHeader.Status::Open);

        OnAfterTestStatusOpen(Rec, PurchHeader);
    end;

    procedure SuspendStatusCheck(Suspend: Boolean)
    begin
        StatusCheckSuspended := Suspend;
    end;

    procedure UpdateLeadTimeFields()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateLeadTimeFields(Rec, IsHandled);
        if IsHandled then
            exit;

        if Type = Type::Item then begin
            GetPurchHeader;

            Evaluate("Lead Time Calculation",
              LeadTimeMgt.PurchaseLeadTime(
                "No.", "Location Code", "Variant Code",
                "Buy-from Vendor No."));
            if Format("Lead Time Calculation") = '' then
                "Lead Time Calculation" := PurchHeader."Lead Time Calculation";
            Evaluate("Safety Lead Time", LeadTimeMgt.SafetyLeadTime("No.", "Location Code", "Variant Code"));
        end;
    end;

    procedure GetUpdateBasicDates()
    begin
        GetPurchHeader;
        if PurchHeader."Expected Receipt Date" <> 0D then
            Validate("Expected Receipt Date", PurchHeader."Expected Receipt Date")
        else
            Validate("Order Date", PurchHeader."Order Date");
    end;

    procedure UpdateDates()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDates(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Promised Receipt Date" <> 0D then
            Validate("Promised Receipt Date")
        else
            if "Requested Receipt Date" <> 0D then
                Validate("Requested Receipt Date")
            else
                GetUpdateBasicDates;

        OnAfterUpdateDates(Rec);
    end;

    procedure InternalLeadTimeDays(PurchDate: Date): Text[30]
    var
        TotalDays: DateFormula;
    begin
        Evaluate(
          TotalDays, '<' + Format(CalcDate("Safety Lead Time", CalcDate("Inbound Whse. Handling Time", PurchDate)) - PurchDate) + 'D>');
        OnAfterInternalLeadTimeDays(Rec, PurchDate, TotalDays);
        exit(Format(TotalDays));
    end;

    local procedure ReversedInternalLeadTimeDays(PurchDate: Date): Text[30]
    var
        TotalDays: DateFormula;
        ReversedSafetyLeadTime: DateFormula;
        ReversedWhseHandlingTime: DateFormula;
    begin
        CalendarMgmt.ReverseDateFormula(ReversedSafetyLeadTime, "Safety Lead Time");
        CalendarMgmt.ReverseDateFormula(ReversedWhseHandlingTime, "Inbound Whse. Handling Time");
        Evaluate(
          TotalDays, '<' + Format(PurchDate - CalcDate(ReversedWhseHandlingTime, CalcDate(ReversedSafetyLeadTime, PurchDate))) + 'D>');
        exit(Format(TotalDays));
    end;

    procedure UpdateVATOnLines(QtyType: Option General,Invoicing,Shipping; var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line") LineWasModified: Boolean
    var
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        Currency: Record Currency;
        NewAmount: Decimal;
        NewAmountIncludingVAT: Decimal;
        NewVATBaseAmount: Decimal;
        VATAmount: Decimal;
        VATDifference: Decimal;
        InvDiscAmount: Decimal;
        LineAmountToInvoice: Decimal;
        LineAmountToInvoiceDiscounted: Decimal;
        DeferralAmount: Decimal;
    begin
        LineWasModified := false;
        if QtyType = QtyType::Shipping then
            exit;
        if PurchHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision
        else
            Currency.Get(PurchHeader."Currency Code");

        TempVATAmountLineRemainder.DeleteAll();

        with PurchLine do begin
            SetRange("Document Type", PurchHeader."Document Type");
            SetRange("Document No.", PurchHeader."No.");
            OnUpdateVATOnLinesOnAfterSetFilters(PurchLine, PurchHeader);
            LockTable();
            if FindSet then
                repeat
                    if not ZeroAmountLine(QtyType) then begin
                        DeferralAmount := GetDeferralAmount;
                        VATAmountLine.Get("VAT Identifier", "VAT Calculation Type", "Tax Group Code", "Use Tax", "Line Amount" >= 0);
                        if VATAmountLine.Modified then begin
                            if not TempVATAmountLineRemainder.Get(
                                 "VAT Identifier", "VAT Calculation Type", "Tax Group Code", "Use Tax", "Line Amount" >= 0)
                            then begin
                                TempVATAmountLineRemainder := VATAmountLine;
                                TempVATAmountLineRemainder.Init();
                                TempVATAmountLineRemainder.Insert();
                            end;

                            if QtyType = QtyType::General then
                                LineAmountToInvoice := "Line Amount"
                            else
                                LineAmountToInvoice :=
                                  Round("Line Amount" * "Qty. to Invoice" / Quantity, Currency."Amount Rounding Precision");

                            if "Allow Invoice Disc." then begin
                                if (VATAmountLine."Inv. Disc. Base Amount" = 0) or (LineAmountToInvoice = 0) then
                                    InvDiscAmount := 0
                                else begin
                                    if QtyType = QtyType::General then
                                        LineAmountToInvoice := "Line Amount"
                                    else
                                        LineAmountToInvoice :=
                                          Round("Line Amount" * "Qty. to Invoice" / Quantity, Currency."Amount Rounding Precision");
                                    LineAmountToInvoiceDiscounted :=
                                      VATAmountLine."Invoice Discount Amount" * LineAmountToInvoice /
                                      VATAmountLine."Inv. Disc. Base Amount";
                                    TempVATAmountLineRemainder."Invoice Discount Amount" :=
                                      TempVATAmountLineRemainder."Invoice Discount Amount" + LineAmountToInvoiceDiscounted;
                                    InvDiscAmount :=
                                      Round(
                                        TempVATAmountLineRemainder."Invoice Discount Amount", Currency."Amount Rounding Precision");
                                    TempVATAmountLineRemainder."Invoice Discount Amount" :=
                                      TempVATAmountLineRemainder."Invoice Discount Amount" - InvDiscAmount;
                                end;
                                if QtyType = QtyType::General then begin
                                    "Inv. Discount Amount" := InvDiscAmount;
                                    CalcInvDiscToInvoice();
                                end else
                                    "Inv. Disc. Amount to Invoice" := InvDiscAmount;
                            end else
                                InvDiscAmount := 0;

                            OnUpdateVATOnLinesOnBeforeCalculateAmounts(PurchLine, PurchHeader);
                            if QtyType = QtyType::General then
                                if PurchHeader."Prices Including VAT" then begin
                                    if (VATAmountLine.CalcLineAmount = 0) or ("Line Amount" = 0) then begin
                                        VATAmount := 0;
                                        NewAmountIncludingVAT := 0;
                                    end else begin
                                        VATAmount :=
                                          TempVATAmountLineRemainder."VAT Amount" +
                                          VATAmountLine."VAT Amount" * CalcLineAmount / VATAmountLine.CalcLineAmount;
                                        NewAmountIncludingVAT :=
                                          TempVATAmountLineRemainder."Amount Including VAT" +
                                          VATAmountLine."Amount Including VAT" * CalcLineAmount / VATAmountLine.CalcLineAmount;
                                    end;
                                    NewAmount :=
                                      Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision") -
                                      Round(VATAmount, Currency."Amount Rounding Precision");
                                    NewVATBaseAmount :=
                                      Round(
                                        NewAmount * (1 - PurchHeader."VAT Base Discount %" / 100),
                                        Currency."Amount Rounding Precision");
                                end else begin
                                    if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then begin
                                        VATAmount := CalcLineAmount();
                                        NewAmount := 0;
                                        NewVATBaseAmount := 0;
                                    end else begin
                                        NewAmount := CalcLineAmount();
                                        NewVATBaseAmount :=
                                          Round(
                                            NewAmount * (1 - PurchHeader."VAT Base Discount %" / 100),
                                            Currency."Amount Rounding Precision");
                                        if VATAmountLine."VAT Base" = 0 then
                                            VATAmount := 0
                                        else
                                            VATAmount :=
                                              TempVATAmountLineRemainder."VAT Amount" +
                                              VATAmountLine."VAT Amount" * NewAmount / VATAmountLine."VAT Base";
                                    end;
                                    NewAmountIncludingVAT := NewAmount + Round(VATAmount, Currency."Amount Rounding Precision");
                                end
                            else begin
                                if VATAmountLine.CalcLineAmount = 0 then
                                    VATDifference := 0
                                else
                                    VATDifference :=
                                      TempVATAmountLineRemainder."VAT Difference" +
                                      VATAmountLine."VAT Difference" * (LineAmountToInvoice - InvDiscAmount) / VATAmountLine.CalcLineAmount;
                                if LineAmountToInvoice = 0 then
                                    "VAT Difference" := 0
                                else
                                    "VAT Difference" := Round(VATDifference, Currency."Amount Rounding Precision");
                            end;
                            OnUpdateVATOnLinesOnAfterCalculateAmounts(PurchLine, PurchHeader);

                            if QtyType = QtyType::General then begin
                                if not "Prepayment Line" then
                                    UpdatePrepmtAmounts();
                                UpdateBaseAmounts(NewAmount, Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision"), NewVATBaseAmount);
                            end;
                            InitOutstanding();
                            if not ((Type = Type::"Charge (Item)") and ("Quantity Invoiced" <> "Qty. Assigned")) then begin
                                SetUpdateFromVAT(true);
                                UpdateUnitCost();
                            end;
                            if Type = Type::"Charge (Item)" then
                                UpdateItemChargeAssgnt();
                            Modify;
                            LineWasModified := true;

                            if ("Deferral Code" <> '') and (DeferralAmount <> GetDeferralAmount()) then
                                UpdateDeferralAmounts();

                            TempVATAmountLineRemainder."Amount Including VAT" :=
                              NewAmountIncludingVAT - Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision");
                            TempVATAmountLineRemainder."VAT Amount" := VATAmount - NewAmountIncludingVAT + NewAmount;
                            TempVATAmountLineRemainder."VAT Difference" := VATDifference - "VAT Difference";
                            TempVATAmountLineRemainder.Modify();
                        end;
                    end;
                until Next = 0;
        end;

        OnAfterUpdateVATOnLines(PurchHeader, PurchLine, VATAmountLine, QtyType);
    end;

    procedure CalcVATAmountLines(QtyType: Option General,Invoicing,Shipping; var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line")
    var
        TotalVATAmount: Decimal;
        QtyToHandle: Decimal;
        AmtToHandle: Decimal;
        RoundingLineInserted: Boolean;
    begin
        if IsCalcVATAmountLinesHandled(PurchHeader, PurchLine, VATAmountLine) then
            exit;

        Currency.Initialize(PurchHeader."Currency Code");

        VATAmountLine.DeleteAll();

        with PurchLine do begin
            SetRange("Document Type", PurchHeader."Document Type");
            SetRange("Document No.", PurchHeader."No.");
            OnCalcVATAmountLinesOnAfterSetFilters(PurchLine, PurchHeader);
            if FindSet then
                repeat
                    if not ZeroAmountLine(QtyType) then begin
                        if (Type = Type::"G/L Account") and not "Prepayment Line" then
                            RoundingLineInserted := (("No." = GetVPGInvRoundAcc(PurchHeader)) and "System-Created Entry") or RoundingLineInserted;
                        if "VAT Calculation Type" in
                           ["VAT Calculation Type"::"Reverse Charge VAT", "VAT Calculation Type"::"Sales Tax"]
                        then
                            "VAT %" := 0;
                        if not VATAmountLine.Get(
                             "VAT Identifier", "VAT Calculation Type", "Tax Group Code", "Use Tax", "Line Amount" >= 0)
                        then
                            VATAmountLine.InsertNewLine(
                              "VAT Identifier", "VAT Calculation Type", "Tax Group Code", "Use Tax", "VAT %", "Line Amount" >= 0, false);

                        case QtyType of
                            QtyType::General:
                                begin
                                    VATAmountLine.Quantity += "Quantity (Base)";
                                    VATAmountLine.SumLine(
                                      "Line Amount", "Inv. Discount Amount", "VAT Difference", "Allow Invoice Disc.", "Prepayment Line");
                                end;
                            QtyType::Invoicing:
                                begin
                                    case true of
                                        ("Document Type" in ["Document Type"::Order, "Document Type"::Invoice]) and
                                      (not PurchHeader.Receive) and PurchHeader.Invoice and (not "Prepayment Line"):
                                            if "Receipt No." = '' then begin
                                                QtyToHandle := GetAbsMin("Qty. to Invoice", "Qty. Rcd. Not Invoiced");
                                                VATAmountLine.Quantity += GetAbsMin("Qty. to Invoice (Base)", "Qty. Rcd. Not Invoiced (Base)");
                                            end else begin
                                                QtyToHandle := "Qty. to Invoice";
                                                VATAmountLine.Quantity += "Qty. to Invoice (Base)";
                                            end;
                                        IsCreditDocType and (not PurchHeader.Ship) and PurchHeader.Invoice:
                                            if "Return Shipment No." = '' then begin
                                                QtyToHandle := GetAbsMin("Qty. to Invoice", "Return Qty. Shipped Not Invd.");
                                                VATAmountLine.Quantity += GetAbsMin("Qty. to Invoice (Base)", "Ret. Qty. Shpd Not Invd.(Base)");
                                            end else begin
                                                QtyToHandle := "Qty. to Invoice";
                                                VATAmountLine.Quantity += "Qty. to Invoice (Base)";
                                            end;
                                        else begin
                                                QtyToHandle := "Qty. to Invoice";
                                                VATAmountLine.Quantity += "Qty. to Invoice (Base)";
                                            end;
                                    end;
                                    AmtToHandle := GetLineAmountToHandleInclPrepmt(QtyToHandle);
                                    if PurchHeader."Invoice Discount Calculation" <> PurchHeader."Invoice Discount Calculation"::Amount then
                                        VATAmountLine.SumLine(
                                          AmtToHandle, Round("Inv. Discount Amount" * QtyToHandle / Quantity, Currency."Amount Rounding Precision"),
                                          "VAT Difference", "Allow Invoice Disc.", "Prepayment Line")
                                    else
                                        VATAmountLine.SumLine(
                                          AmtToHandle, "Inv. Disc. Amount to Invoice", "VAT Difference", "Allow Invoice Disc.", "Prepayment Line");
                                end;
                            QtyType::Shipping:
                                begin
                                    if "Document Type" in
                                       ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]
                                    then begin
                                        QtyToHandle := "Return Qty. to Ship";
                                        VATAmountLine.Quantity += "Return Qty. to Ship (Base)";
                                    end else begin
                                        QtyToHandle := "Qty. to Receive";
                                        VATAmountLine.Quantity += "Qty. to Receive (Base)";
                                    end;
                                    AmtToHandle := GetLineAmountToHandleInclPrepmt(QtyToHandle);
                                    VATAmountLine.SumLine(
                                      AmtToHandle, Round("Inv. Discount Amount" * QtyToHandle / Quantity, Currency."Amount Rounding Precision"),
                                      "VAT Difference", "Allow Invoice Disc.", "Prepayment Line");
                                end;
                        end;
                        TotalVATAmount += "Amount Including VAT" - Amount;
                        OnCalcVATAmountLinesOnAfterCalcLineTotals(VATAmountLine, PurchHeader, PurchLine, Currency, QtyType, TotalVATAmount);
                    end;
                until Next = 0;
        end;

        VATAmountLine.UpdateLines(
          TotalVATAmount, Currency, PurchHeader."Currency Factor", PurchHeader."Prices Including VAT",
          PurchHeader."VAT Base Discount %", PurchHeader."Tax Area Code", PurchHeader."Tax Liable", PurchHeader."Posting Date");

        if RoundingLineInserted and (TotalVATAmount <> 0) then
            if GetVATAmountLineOfMaxAmt(VATAmountLine, PurchLine) then begin
                VATAmountLine."VAT Amount" += TotalVATAmount;
                VATAmountLine."Amount Including VAT" += TotalVATAmount;
                VATAmountLine."Calculated VAT Amount" += TotalVATAmount;
                VATAmountLine.Modify();
            end;

        OnAfterCalcVATAmountLines(PurchHeader, PurchLine, VATAmountLine, QtyType);
    end;

    local procedure GetVATAmountLineOfMaxAmt(var VATAmountLine: Record "VAT Amount Line"; PurchaseLine: Record "Purchase Line"): Boolean
    var
        VATAmount1: Decimal;
        VATAmount2: Decimal;
        IsPositive1: Boolean;
        IsPositive2: Boolean;
    begin
        if VATAmountLine.Get(
             PurchaseLine."VAT Identifier", PurchaseLine."VAT Calculation Type", PurchaseLine."Tax Group Code", false, false)
        then begin
            VATAmount1 := VATAmountLine."VAT Amount";
            IsPositive1 := VATAmountLine.Positive;
        end;
        if VATAmountLine.Get(
             PurchaseLine."VAT Identifier", PurchaseLine."VAT Calculation Type", PurchaseLine."Tax Group Code", false, true)
        then begin
            VATAmount2 := VATAmountLine."VAT Amount";
            IsPositive2 := VATAmountLine.Positive;
        end;
        if Abs(VATAmount1) >= Abs(VATAmount2) then
            exit(
              VATAmountLine.Get(
                PurchaseLine."VAT Identifier", PurchaseLine."VAT Calculation Type", PurchaseLine."Tax Group Code", false, IsPositive1));
        exit(
          VATAmountLine.Get(
            PurchaseLine."VAT Identifier", PurchaseLine."VAT Calculation Type", PurchaseLine."Tax Group Code", false, IsPositive2));
    end;

    procedure UpdateWithWarehouseReceive()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateWithWarehouseReceive(Rec, IsHandled);
        if IsHandled then
            exit;

        if IsInventoriableItem() then
            case true of
                ("Document Type" in ["Document Type"::Quote, "Document Type"::Order]) and (Quantity >= 0):
                    if Location.RequireReceive("Location Code") then
                        Validate("Qty. to Receive", 0)
                    else
                        Validate("Qty. to Receive", "Outstanding Quantity");
                ("Document Type" in ["Document Type"::Quote, "Document Type"::Order]) and (Quantity < 0):
                    if Location.RequireShipment("Location Code") then
                        Validate("Qty. to Receive", 0)
                    else
                        Validate("Qty. to Receive", "Outstanding Quantity");
                ("Document Type" = "Document Type"::"Return Order") and (Quantity >= 0):
                    if Location.RequireShipment("Location Code") then
                        Validate("Return Qty. to Ship", 0)
                    else
                        Validate("Return Qty. to Ship", "Outstanding Quantity");
                ("Document Type" = "Document Type"::"Return Order") and (Quantity < 0):
                    if Location.RequireReceive("Location Code") then
                        Validate("Return Qty. to Ship", 0)
                    else
                        Validate("Return Qty. to Ship", "Outstanding Quantity");
            end;

        GetPurchHeader;
        OnAfterUpdateWithWarehouseReceive(PurchHeader, Rec);

        SetDefaultQuantity;
    end;

    local procedure CheckWarehouse()
    var
        Location2: Record Location;
        WhseSetup: Record "Warehouse Setup";
        ShowDialog: Option " ",Message,Error;
        DialogText: Text[50];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWarehouse(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Prod. Order No." <> '' then
            exit;

        GetLocation("Location Code");
        if "Location Code" = '' then begin
            WhseSetup.Get();
            Location2."Require Shipment" := WhseSetup."Require Shipment";
            Location2."Require Pick" := WhseSetup."Require Pick";
            Location2."Require Receive" := WhseSetup."Require Receive";
            Location2."Require Put-away" := WhseSetup."Require Put-away";
        end else
            Location2 := Location;

        DialogText := Text033;
        if ("Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"]) and
           Location2."Directed Put-away and Pick"
        then begin
            ShowDialog := ShowDialog::Error;
            if (("Document Type" = "Document Type"::Order) and (Quantity >= 0)) or
               (("Document Type" = "Document Type"::"Return Order") and (Quantity < 0))
            then
                DialogText :=
                  DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Receive"))
            else
                DialogText :=
                  DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Shipment"));
        end else begin
            if (("Document Type" = "Document Type"::Order) and (Quantity >= 0) and
                (Location2."Require Receive" or Location2."Require Put-away")) or
               (("Document Type" = "Document Type"::"Return Order") and (Quantity < 0) and
                (Location2."Require Receive" or Location2."Require Put-away"))
            then begin
                if WhseValidateSourceLine.WhseLinesExist(
                     DATABASE::"Purchase Line",
                     "Document Type",
                     "Document No.",
                     "Line No.",
                     0,
                     Quantity)
                then
                    ShowDialog := ShowDialog::Error
                else
                    if Location2."Require Receive" then
                        ShowDialog := ShowDialog::Message;
                if Location2."Require Receive" then
                    DialogText :=
                      DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Receive"))
                else begin
                    DialogText := Text034;
                    DialogText :=
                      DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Put-away"));
                end;
            end;

            if (("Document Type" = "Document Type"::Order) and (Quantity < 0) and
                (Location2."Require Shipment" or Location2."Require Pick")) or
               (("Document Type" = "Document Type"::"Return Order") and (Quantity >= 0) and
                (Location2."Require Shipment" or Location2."Require Pick"))
            then begin
                if WhseValidateSourceLine.WhseLinesExist(
                     DATABASE::"Purchase Line",
                     "Document Type",
                     "Document No.",
                     "Line No.",
                     0,
                     Quantity)
                then
                    ShowDialog := ShowDialog::Error
                else
                    if Location2."Require Shipment" then
                        ShowDialog := ShowDialog::Message;
                if Location2."Require Shipment" then
                    DialogText :=
                      DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Shipment"))
                else begin
                    DialogText := Text034;
                    DialogText :=
                      DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Pick"));
                end;
            end;
        end;

        case ShowDialog of
            ShowDialog::Message:
                Message(WhseRequirementMsg, DialogText);
            ShowDialog::Error:
                Error(Text016, DialogText, FieldCaption("Line No."), "Line No.")
        end;

        HandleDedicatedBin(true);
    end;

    local procedure GetOverheadRateFCY(): Decimal
    var
        Item: Record Item;
        QtyPerUOM: Decimal;
    begin
        if "Prod. Order No." = '' then
            QtyPerUOM := "Qty. per Unit of Measure"
        else begin
            GetItem(Item);
            QtyPerUOM := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
        end;

        exit(
          CurrExchRate.ExchangeAmtLCYToFCY(
            GetDate, "Currency Code", "Overhead Rate" * QtyPerUOM, PurchHeader."Currency Factor"));
    end;

    procedure GetItemTranslation()
    var
        ItemTranslation: Record "Item Translation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetItemTranslation(Rec, IsHandled);
        if IsHandled then
            exit;

        GetPurchHeader;
        if ItemTranslation.Get("No.", "Variant Code", PurchHeader."Language Code") then begin
            Description := ItemTranslation.Description;
            "Description 2" := ItemTranslation."Description 2";
            OnAfterGetItemTranslation(Rec, PurchHeader, ItemTranslation);
        end;
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    local procedure GetPurchSetup()
    begin
        if not PurchSetupRead then
            PurchSetup.Get();
        PurchSetupRead := true;

        OnAfterGetPurchSetup(Rec, PurchSetup);
    end;

    procedure AdjustDateFormula(DateFormulatoAdjust: DateFormula): Text[30]
    begin
        if Format(DateFormulatoAdjust) <> '' then
            exit(Format(DateFormulatoAdjust));
        Evaluate(DateFormulatoAdjust, '<0D>');
        exit(Format(DateFormulatoAdjust));
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(ItemTrackingMgt.ComposeRowID(DATABASE::"Purchase Line", "Document Type",
            "Document No.", '', 0, "Line No."));
    end;

    local procedure GetDefaultBin()
    var
        WMSManagement: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDefaultBin(Rec, IsHandled);
        if IsHandled then
            exit;

        if Type <> Type::Item then
            exit;

        "Bin Code" := '';
        if "Drop Shipment" then
            exit;

        if ("Location Code" <> '') and ("No." <> '') then begin
            GetLocation("Location Code");
            if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then begin
                WMSManagement.GetDefaultBin("No.", "Variant Code", "Location Code", "Bin Code");
                HandleDedicatedBin(false);
            end;
        end;
    end;

    procedure IsInbound(): Boolean
    begin
        case "Document Type" of
            "Document Type"::Order, "Document Type"::Invoice, "Document Type"::Quote, "Document Type"::"Blanket Order":
                exit("Quantity (Base)" > 0);
            "Document Type"::"Return Order", "Document Type"::"Credit Memo":
                exit("Quantity (Base)" < 0);
        end;

        exit(false);
    end;

    local procedure HandleDedicatedBin(IssueWarning: Boolean)
    var
        WhseIntegrationMgt: Codeunit "Whse. Integration Management";
    begin
        if not IsInbound and ("Quantity (Base)" <> 0) then
            WhseIntegrationMgt.CheckIfBinDedicatedOnSrcDoc("Location Code", "Bin Code", IssueWarning);
    end;

    procedure CrossReferenceNoLookUp()
    var
        ItemCrossReference: Record "Item Cross Reference";
        PriceCalculation: Interface "Price Calculation";
    begin
        if Type = Type::Item then begin
            GetPurchHeader;
            ItemCrossReference.Reset();
            ItemCrossReference.SetCurrentKey("Cross-Reference Type", "Cross-Reference Type No.");
            ItemCrossReference.SetFilter(
              "Cross-Reference Type", '%1|%2',
              ItemCrossReference."Cross-Reference Type"::Vendor,
              ItemCrossReference."Cross-Reference Type"::" ");
            ItemCrossReference.SetFilter("Cross-Reference Type No.", '%1|%2', PurchHeader."Buy-from Vendor No.", '');
            OnCrossReferenceNoLookUpOnAfterSetFilters(ItemCrossReference, Rec);
            if PAGE.RunModal(PAGE::"Cross Reference List", ItemCrossReference) = ACTION::LookupOK then begin
                "Cross-Reference No." := ItemCrossReference."Cross-Reference No.";
                ValidateCrossReferenceNo(ItemCrossReference, false);
                Validate("Cross-Reference No.", ItemCrossReference."Cross-Reference No.");

                GetPriceCalculationHandler(PurchHeader, PriceCalculation);
                PriceCalculation.ApplyPrice(FieldNo("Cross-Reference No."));
                PriceCalculation.ApplyDiscount();
                GetLineWithPrice(PriceCalculation);

                OnCrossReferenceNoLookupOnBeforeValidateDirectUnitCost(PurchHeader, Rec);
                Validate("Direct Unit Cost");
            end;
        end;
    end;

    local procedure ValidateCrossReferenceNo(ItemCrossReference: Record "Item Cross Reference"; SearchItem: Boolean)
    var
        ReturnedItemCrossReference: Record "Item Cross Reference";
    begin
        ReturnedItemCrossReference.Init();
        if "Cross-Reference No." <> '' then begin
            if SearchItem then
                DistIntegration.ICRLookupPurchaseItem(Rec, ReturnedItemCrossReference, CurrFieldNo <> 0)
            else
                ReturnedItemCrossReference := ItemCrossReference;

            OnValidateCrossReferenceNoOnBeforeAssignNo(Rec, ReturnedItemCrossReference);

            if "Cross-Reference No." <> xRec."Cross-Reference No." then
                PlanPriceCalcByField(FieldNo("Cross-Reference No."));
            Validate("No.", ReturnedItemCrossReference."Item No.");
            SetVendorItemNo;
            if ReturnedItemCrossReference."Variant Code" <> '' then
                Validate("Variant Code", ReturnedItemCrossReference."Variant Code");
            if ReturnedItemCrossReference."Unit of Measure" <> '' then
                Validate("Unit of Measure Code", ReturnedItemCrossReference."Unit of Measure");
        end;

        "Unit of Measure (Cross Ref.)" := ReturnedItemCrossReference."Unit of Measure";
        "Cross-Reference Type" := ReturnedItemCrossReference."Cross-Reference Type";
        "Cross-Reference Type No." := ReturnedItemCrossReference."Cross-Reference Type No.";
        "Cross-Reference No." := ReturnedItemCrossReference."Cross-Reference No.";

        if (ReturnedItemCrossReference.Description <> '') or (ReturnedItemCrossReference."Description 2" <> '') then begin
            Description := ReturnedItemCrossReference.Description;
            "Description 2" := ReturnedItemCrossReference."Description 2";
        end;

        UpdateDirectUnitCostByField(FieldNo("Cross-Reference No."));
        UpdateICPartner;

        OnAfterValidateCrossReferenceNo(Rec, ItemCrossReference);
    end;

    procedure ItemExists(ItemNo: Code[20]): Boolean
    var
        Item2: Record Item;
    begin
        if Type = Type::Item then
            if not Item2.Get(ItemNo) then
                exit(false);
        exit(true);
    end;

    local procedure FindOrCreateRecordByNo(SourceNo: Code[20]): Code[20]
    var
        Item: Record Item;
        FindRecordManagement: Codeunit "Find Record Management";
        FoundNo: Text;
    begin
        GetPurchSetup;

        if Type = Type::Item then begin
            if Item.TryGetItemNoOpenCardWithView(
                 FoundNo, SourceNo, PurchSetup."Create Item from Item No.", true, PurchSetup."Create Item from Item No.", '')
            then
                exit(CopyStr(FoundNo, 1, MaxStrLen("No.")))
        end else
            exit(FindRecordManagement.FindNoFromTypedValue(Type, "No.", not "System-Created Entry"));

        exit(SourceNo);
    end;

    local procedure GetAbsMin(QtyToHandle: Decimal; QtyHandled: Decimal): Decimal
    begin
        if Abs(QtyHandled) < Abs(QtyToHandle) then
            exit(QtyHandled);

        exit(QtyToHandle);
    end;

    local procedure CheckApplToItemLedgEntry(): Code[10]
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ApplyRec: Record "Item Application Entry";
        ItemTrackingLines: Page "Item Tracking Lines";
        ReturnedQty: Decimal;
        RemainingtobeReturnedQty: Decimal;
    begin
        if "Appl.-to Item Entry" = 0 then
            exit;

        if "Receipt No." <> '' then
            exit;

        TestField(Type, Type::Item);
        TestField(Quantity);
        if Signed(Quantity) > 0 then
            TestField("Prod. Order No.", '');
        if IsCreditDocType then begin
            if Quantity < 0 then
                FieldError(Quantity, Text029);
        end else begin
            if Quantity > 0 then
                FieldError(Quantity, Text030);
        end;
        ItemLedgEntry.Get("Appl.-to Item Entry");
        ItemLedgEntry.TestField(Positive, true);
        if ItemLedgEntry.TrackingExists then
            Error(Text040, ItemTrackingLines.Caption, FieldCaption("Appl.-to Item Entry"));

        ItemLedgEntry.TestField("Item No.", "No.");
        ItemLedgEntry.TestField("Variant Code", "Variant Code");

        // Track qty in both alternative and base UOM for better error checking and reporting
        if Abs("Quantity (Base)") > ItemLedgEntry.Quantity then
            Error(
              Text042,
              ItemLedgEntry.Quantity, ItemLedgEntry.FieldCaption("Document No."),
              ItemLedgEntry."Document No.");

        if IsCreditDocType then
            if Abs("Outstanding Qty. (Base)") > ItemLedgEntry."Remaining Quantity" then begin
                ReturnedQty := ApplyRec.Returned(ItemLedgEntry."Entry No.");
                RemainingtobeReturnedQty := ItemLedgEntry.Quantity - ReturnedQty;
                if not ("Qty. per Unit of Measure" = 0) then begin
                    ReturnedQty := Round(ReturnedQty / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
                    RemainingtobeReturnedQty := Round(RemainingtobeReturnedQty / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
                end;

                if ((("Qty. per Unit of Measure" = 0) and (RemainingtobeReturnedQty < Abs("Outstanding Qty. (Base)"))) or
                    (("Qty. per Unit of Measure" <> 0) and (RemainingtobeReturnedQty < Abs("Outstanding Quantity"))))
                then
                    Error(
                      Text035,
                      ReturnedQty, ItemLedgEntry.FieldCaption("Document No."),
                      ItemLedgEntry."Document No.", RemainingtobeReturnedQty);
            end;

        exit(ItemLedgEntry."Location Code");
    end;

    procedure CalcPrepaymentToDeduct()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcPrepaymentToDeduct(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Qty. to Invoice" <> 0) and ("Prepmt. Amt. Inv." <> 0) then begin
            GetPurchHeader;
            if ("Prepayment %" = 100) and not IsFinalInvoice then
                "Prepmt Amt to Deduct" := GetLineAmountToHandle("Qty. to Invoice")
            else
                "Prepmt Amt to Deduct" :=
                  Round(
                    ("Prepmt. Amt. Inv." - "Prepmt Amt Deducted") *
                    "Qty. to Invoice" / (Quantity - "Quantity Invoiced"), Currency."Amount Rounding Precision")
        end else
            "Prepmt Amt to Deduct" := 0
    end;

    procedure IsFinalInvoice(): Boolean
    begin
        exit("Qty. to Invoice" = Quantity - "Quantity Invoiced");
    end;

    procedure GetLineAmountToHandle(QtyToHandle: Decimal): Decimal
    var
        LineAmount: Decimal;
        LineDiscAmount: Decimal;
    begin
        if "Line Discount %" = 100 then
            exit(0);

        GetPurchHeader;

        if "Prepmt Amt to Deduct" = 0 then
            LineAmount := Round(QtyToHandle * "Direct Unit Cost", Currency."Amount Rounding Precision")
        else
            if Quantity <> 0 then begin
                LineAmount := Round(Quantity * "Direct Unit Cost", Currency."Amount Rounding Precision");
                LineAmount := Round(QtyToHandle * LineAmount / Quantity, Currency."Amount Rounding Precision");
            end else
                LineAmount := 0;

        if QtyToHandle <> Quantity then
            LineDiscAmount := Round(LineAmount * "Line Discount %" / 100, Currency."Amount Rounding Precision")
        else
            LineDiscAmount := "Line Discount Amount";

        OnAfterGetLineAmountToHandle(Rec, QtyToHandle, LineAmount, LineDiscAmount);
        exit(LineAmount - LineDiscAmount);
    end;

    procedure GetLineAmountToHandleInclPrepmt(QtyToHandle: Decimal): Decimal
    var
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        DocType: Option Invoice,"Credit Memo",Statistic;
    begin
        if "Line Discount %" = 100 then
            exit(0);

        if IsCreditDocType() then
            DocType := DocType::"Credit Memo"
        else
            DocType := DocType::Invoice;

        if ("Prepayment %" = 100) and not "Prepayment Line" and ("Prepmt Amt to Deduct" <> 0) and ("Inv. Discount Amount" = 0) then
            if PurchasePostPrepayments.PrepmtAmount(Rec, DocType) <= 0 then
                exit("Prepmt Amt to Deduct");
        exit(GetLineAmountToHandle(QtyToHandle));
    end;

    procedure JobTaskIsSet(): Boolean
    var
        JobTaskSet: Boolean;
    begin
        JobTaskSet := ("Job No." <> '') AND ("Job Task No." <> '') AND (Type IN [Type::"G/L Account", Type::Item]);
        OnBeforeJobTaskIsSet(Rec, JobTaskSet);
        exit(JobTaskSet);
    end;

    procedure CreateTempJobJnlLine(GetPrices: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTempJobJnlLine(TempJobJnlLine, Rec, xRec, GetPrices, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        GetPurchHeader;
        Clear(TempJobJnlLine);
        TempJobJnlLine.DontCheckStdCost;
        TempJobJnlLine.Validate("Job No.", "Job No.");
        TempJobJnlLine.Validate("Job Task No.", "Job Task No.");
        TempJobJnlLine.Validate("Posting Date", PurchHeader."Posting Date");
        TempJobJnlLine.SetCurrencyFactor("Job Currency Factor");
        if Type = Type::"G/L Account" then
            TempJobJnlLine.Validate(Type, TempJobJnlLine.Type::"G/L Account")
        else
            TempJobJnlLine.Validate(Type, TempJobJnlLine.Type::Item);
        TempJobJnlLine.Validate("No.", "No.");
        TempJobJnlLine.Validate(Quantity, Quantity);
        TempJobJnlLine.Validate("Variant Code", "Variant Code");
        TempJobJnlLine.Validate("Unit of Measure Code", "Unit of Measure Code");

        if not GetPrices then begin
            if xRec."Line No." <> 0 then begin
                TempJobJnlLine."Unit Cost" := xRec."Unit Cost";
                TempJobJnlLine."Unit Cost (LCY)" := xRec."Unit Cost (LCY)";
                TempJobJnlLine."Unit Price" := xRec."Job Unit Price";
                TempJobJnlLine."Line Amount" := xRec."Job Line Amount";
                TempJobJnlLine."Line Discount %" := xRec."Job Line Discount %";
                TempJobJnlLine."Line Discount Amount" := xRec."Job Line Discount Amount";
            end else begin
                TempJobJnlLine."Unit Cost" := "Unit Cost";
                TempJobJnlLine."Unit Cost (LCY)" := "Unit Cost (LCY)";
                TempJobJnlLine."Unit Price" := "Job Unit Price";
                TempJobJnlLine."Line Amount" := "Job Line Amount";
                TempJobJnlLine."Line Discount %" := "Job Line Discount %";
                TempJobJnlLine."Line Discount Amount" := "Job Line Discount Amount";
            end;
            TempJobJnlLine.Validate("Unit Price");
        end else
            TempJobJnlLine.Validate("Unit Cost (LCY)", "Unit Cost (LCY)");

        OnAfterCreateTempJobJnlLine(TempJobJnlLine, Rec, xRec, GetPrices, CurrFieldNo);
    end;

    procedure UpdateJobPrices()
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        if "Receipt No." = '' then begin
            "Job Unit Price" := TempJobJnlLine."Unit Price";
            "Job Total Price" := TempJobJnlLine."Total Price";
            "Job Unit Price (LCY)" := TempJobJnlLine."Unit Price (LCY)";
            "Job Total Price (LCY)" := TempJobJnlLine."Total Price (LCY)";
            "Job Line Amount (LCY)" := TempJobJnlLine."Line Amount (LCY)";
            "Job Line Disc. Amount (LCY)" := TempJobJnlLine."Line Discount Amount (LCY)";
            "Job Line Amount" := TempJobJnlLine."Line Amount";
            "Job Line Discount %" := TempJobJnlLine."Line Discount %";
            "Job Line Discount Amount" := TempJobJnlLine."Line Discount Amount";
        end else begin
            PurchRcptLine.Get("Receipt No.", "Receipt Line No.");
            "Job Unit Price" := PurchRcptLine."Job Unit Price";
            "Job Total Price" := PurchRcptLine."Job Total Price";
            "Job Unit Price (LCY)" := PurchRcptLine."Job Unit Price (LCY)";
            "Job Total Price (LCY)" := PurchRcptLine."Job Total Price (LCY)";
            "Job Line Amount (LCY)" := PurchRcptLine."Job Line Amount (LCY)";
            "Job Line Disc. Amount (LCY)" := PurchRcptLine."Job Line Disc. Amount (LCY)";
            "Job Line Amount" := PurchRcptLine."Job Line Amount";
            "Job Line Discount %" := PurchRcptLine."Job Line Discount %";
            "Job Line Discount Amount" := PurchRcptLine."Job Line Discount Amount";
        end;

        OnAfterUpdateJobPrices(Rec, TempJobJnlLine, PurchRcptLine);
    end;

    procedure JobSetCurrencyFactor()
    var
        IsHandled: Boolean;
    begin
        GetPurchHeader;
        IsHandled := false;
        OnBeforeJobSetCurrencyFactor(Rec, IsHandled);
        if IsHandled then
            exit;

        Clear(TempJobJnlLine);
        TempJobJnlLine.Validate("Job No.", "Job No.");
        TempJobJnlLine.Validate("Job Task No.", "Job Task No.");
        TempJobJnlLine.Validate("Posting Date", PurchHeader."Posting Date");
        "Job Currency Factor" := TempJobJnlLine."Currency Factor";
    end;

    procedure SetUpdateFromVAT(UpdateFromVAT2: Boolean)
    begin
        UpdateFromVAT := UpdateFromVAT2;
    end;

    procedure InitQtyToReceive2()
    begin
        "Qty. to Receive" := "Outstanding Quantity";
        "Qty. to Receive (Base)" := "Outstanding Qty. (Base)";

        OnAfterInitQtyToReceive2(Rec, CurrFieldNo);

        "Qty. to Invoice" := MaxQtyToInvoice;
        "Qty. to Invoice (Base)" := MaxQtyToInvoiceBase;
        "VAT Difference" := 0;

        OnInitQtyToReceive2OnBeforeCalcInvDiscToInvoice(Rec, xRec);

        CalcInvDiscToInvoice;

        CalcPrepaymentToDeduct;

        if "Job Planning Line No." <> 0 then
            Validate("Job Planning Line No.");

        OnAfterInitQtyToReceive2Procedure(Rec);
    end;

    procedure ClearQtyIfBlank()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeClearQtyIfBlank(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Document Type" = "Document Type"::Order then begin
            GetPurchSetup;
            if PurchSetup."Default Qty. to Receive" = PurchSetup."Default Qty. to Receive"::Blank then begin
                "Qty. to Receive" := 0;
                "Qty. to Receive (Base)" := 0;
            end;
        end;
    end;

    procedure ShowLineComments()
    var
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        TestField("Document No.");
        TestField("Line No.");
        PurchCommentLine.ShowComments("Document Type", "Document No.", "Line No.");
    end;

    procedure SetDefaultQuantity()
    begin
        GetPurchSetup;
        if PurchSetup."Default Qty. to Receive" = PurchSetup."Default Qty. to Receive"::Blank then begin
            if ("Document Type" = "Document Type"::Order) or ("Document Type" = "Document Type"::Quote) then begin
                "Qty. to Receive" := 0;
                "Qty. to Receive (Base)" := 0;
                "Qty. to Invoice" := 0;
                "Qty. to Invoice (Base)" := 0;
            end;
            if "Document Type" = "Document Type"::"Return Order" then begin
                "Return Qty. to Ship" := 0;
                "Return Qty. to Ship (Base)" := 0;
                "Qty. to Invoice" := 0;
                "Qty. to Invoice (Base)" := 0;
            end;
        end;

        OnAfterSetDefaultQuantity(Rec, xRec);
    end;

    procedure UpdatePrePaymentAmounts()
    var
        ReceiptLine: Record "Purch. Rcpt. Line";
        PurchOrderLine: Record "Purchase Line";
        PurchOrderHeader: Record "Purchase Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePrepmtAmounts(Rec, PurchHeader, IsHandled);
        if IsHandled then
            exit;

        if ("Document Type" <> "Document Type"::Invoice) or ("Prepayment %" = 0) then
            exit;

        if not ReceiptLine.Get("Receipt No.", "Receipt Line No.") then begin
            "Prepmt Amt to Deduct" := 0;
            "Prepmt VAT Diff. to Deduct" := 0;
        end else
            if PurchOrderLine.Get(PurchOrderLine."Document Type"::Order, ReceiptLine."Order No.", ReceiptLine."Order Line No.") then begin
                if ("Prepayment %" = 100) and (Quantity <> PurchOrderLine.Quantity - PurchOrderLine."Quantity Invoiced") then
                    "Prepmt Amt to Deduct" := "Line Amount"
                else
                    "Prepmt Amt to Deduct" :=
                      Round((PurchOrderLine."Prepmt. Amt. Inv." - PurchOrderLine."Prepmt Amt Deducted") *
                        Quantity / (PurchOrderLine.Quantity - PurchOrderLine."Quantity Invoiced"), Currency."Amount Rounding Precision");
                "Prepmt VAT Diff. to Deduct" := "Prepayment VAT Difference" - "Prepmt VAT Diff. Deducted";
                PurchOrderHeader.Get(PurchOrderHeader."Document Type"::Order, PurchOrderLine."Document No.");
            end else begin
                "Prepmt Amt to Deduct" := 0;
                "Prepmt VAT Diff. to Deduct" := 0;
            end;

        GetPurchHeader;
        PurchHeader.TestField("Prices Including VAT", PurchOrderHeader."Prices Including VAT");
        if PurchHeader."Prices Including VAT" then begin
            "Prepmt. Amt. Incl. VAT" := "Prepmt Amt to Deduct";
            "Prepayment Amount" :=
              Round(
                "Prepmt Amt to Deduct" / (1 + ("Prepayment VAT %" / 100)),
                Currency."Amount Rounding Precision");
        end else begin
            "Prepmt. Amt. Incl. VAT" :=
              Round(
                "Prepmt Amt to Deduct" * (1 + ("Prepayment VAT %" / 100)),
                Currency."Amount Rounding Precision");
            "Prepayment Amount" := "Prepmt Amt to Deduct";
        end;
        "Prepmt. Line Amount" := "Prepmt Amt to Deduct";
        "Prepmt. Amt. Inv." := "Prepmt. Line Amount";
        "Prepmt. VAT Base Amt." := "Prepayment Amount";
        "Prepmt. Amount Inv. Incl. VAT" := "Prepmt. Amt. Incl. VAT";
        "Prepmt Amt Deducted" := 0;
    end;

    procedure SetVendorItemNo()
    var
        Item: Record Item;
        ItemVend: Record "Item Vendor";
    begin
        GetItem(Item);
        ItemVend.Init();
        ItemVend."Vendor No." := "Buy-from Vendor No.";
        ItemVend."Variant Code" := "Variant Code";
        Item.FindItemVend(ItemVend, "Location Code");
        Validate("Vendor Item No.", ItemVend."Vendor Item No.");
    end;

    procedure ZeroAmountLine(QtyType: Option General,Invoicing,Shipping): Boolean
    begin
        if Type = Type::" " then
            exit(true);
        if Quantity = 0 then
            exit(true);
        if "Direct Unit Cost" = 0 then
            exit(true);
        if QtyType = QtyType::Invoicing then
            if "Qty. to Invoice" = 0 then
                exit(true);
        exit(false);
    end;

    procedure FilterLinesWithItemToPlan(var Item: Record Item; DocumentType: Option)
    begin
        Reset;
        SetCurrentKey("Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Expected Receipt Date");
        SetRange("Document Type", DocumentType);
        SetRange(Type, Type::Item);
        SetRange("No.", Item."No.");
        SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        SetFilter("Location Code", Item.GetFilter("Location Filter"));
        SetFilter("Drop Shipment", Item.GetFilter("Drop Shipment Filter"));
        SetFilter("Expected Receipt Date", Item.GetFilter("Date Filter"));
        SetFilter("Shortcut Dimension 1 Code", Item.GetFilter("Global Dimension 1 Filter"));
        SetFilter("Shortcut Dimension 2 Code", Item.GetFilter("Global Dimension 2 Filter"));
        SetFilter("Outstanding Qty. (Base)", '<>0');
        SetFilter("Unit of Measure Code", Item.GetFilter("Unit of Measure Filter"));

        OnAfterFilterLinesWithItemToPlan(Rec, Item, DocumentType);
    end;

    procedure FindLinesWithItemToPlan(var Item: Record Item; DocumentType: Option): Boolean
    begin
        FilterLinesWithItemToPlan(Item, DocumentType);
        exit(Find('-'));
    end;

    procedure LinesWithItemToPlanExist(var Item: Record Item; DocumentType: Option): Boolean
    begin
        FilterLinesWithItemToPlan(Item, DocumentType);
        exit(not IsEmpty);
    end;

    procedure FilterLinesForReservation(ReservationEntry: Record "Reservation Entry"; DocumentType: Option; AvailabilityFilter: Text; Positive: Boolean)
    var
        IsHandled: Boolean;
    begin
        Reset;
        SetCurrentKey(
          "Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Expected Receipt Date");
        SetRange("Document Type", DocumentType);
        SetRange(Type, Type::Item);
        SetRange("No.", ReservationEntry."Item No.");
        IsHandled := false;
        OnFilterLinesForReservationOnBeforeSetFilterVariantCode(Rec, ReservationEntry, Positive, IsHandled);
        if not IsHandled then
            SetRange("Variant Code", ReservationEntry."Variant Code");
        SetRange("Drop Shipment", false);
        SetRange("Location Code", ReservationEntry."Location Code");
        SetFilter("Expected Receipt Date", AvailabilityFilter);
        if Positive and (DocumentType <> "Document Type"::"Return Order") then
            SetFilter("Quantity (Base)", '>0')
        else
            SetFilter("Quantity (Base)", '<0');
        SetRange("Job No.", ' ');
    end;

    procedure GetVPGInvRoundAcc(var PurchHeader: Record "Purchase Header"): Code[20]
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        GetPurchSetup;
        if PurchSetup."Invoice Rounding" then
            if Vendor.Get(PurchHeader."Pay-to Vendor No.") then
                VendorPostingGroup.Get(Vendor."Vendor Posting Group");

        exit(VendorPostingGroup."Invoice Rounding Account");
    end;

    local procedure CheckReceiptRelation()
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.Get("Receipt No.", "Receipt Line No.");
        if (Quantity * PurchRcptLine."Qty. Rcd. Not Invoiced") < 0 then
            FieldError("Qty. to Invoice", Text051);
        if Abs(Quantity) > Abs(PurchRcptLine."Qty. Rcd. Not Invoiced") then
            Error(Text052, PurchRcptLine."Document No.");

        OnAfterCheckReceiptRelation(Rec, PurchRcptLine);
    end;

    local procedure CheckRetShptRelation()
    var
        ReturnShptLine: Record "Return Shipment Line";
    begin
        ReturnShptLine.Get("Return Shipment No.", "Return Shipment Line No.");
        if (Quantity * (ReturnShptLine.Quantity - ReturnShptLine."Quantity Invoiced")) < 0 then
            FieldError("Qty. to Invoice", Text053);
        if Abs(Quantity) > Abs(ReturnShptLine.Quantity - ReturnShptLine."Quantity Invoiced") then
            Error(Text054, ReturnShptLine."Document No.");

        OnAfterCheckRetShptRelation(Rec, ReturnShptLine);
    end;

    local procedure VerifyItemLineDim()
    begin
        if IsReceivedShippedItemDimChanged then
            ConfirmReceivedShippedItemDimChange;
    end;

    procedure IsReceivedShippedItemDimChanged(): Boolean
    begin
        exit(("Dimension Set ID" <> xRec."Dimension Set ID") and (Type = Type::Item) and
          (("Qty. Rcd. Not Invoiced" <> 0) or ("Return Qty. Shipped Not Invd." <> 0)));
    end;

    local procedure IsServiceCharge(): Boolean
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if Type <> Type::"G/L Account" then
            exit(false);

        GetPurchHeader;
        VendorPostingGroup.Get(PurchHeader."Vendor Posting Group");
        exit(VendorPostingGroup."Service Charge Acc." = "No.");
    end;

    procedure ConfirmReceivedShippedItemDimChange(): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text049, TableCaption), true) then
            Error(Text050);

        exit(true);
    end;

    procedure InitType()
    begin
        if "Document No." <> '' then begin
            if not PurchHeader.Get("Document Type", "Document No.") then
                exit;
            if (PurchHeader.Status = PurchHeader.Status::Released) and
               (xRec.Type in [xRec.Type::Item, xRec.Type::"Fixed Asset"])
            then
                Type := Type::" "
            else
                Type := xRec.Type;
        end;

        OnAfterInitType(rec, xRec);
    end;

    local procedure CheckWMS()
    begin
        if CurrFieldNo <> 0 then
            CheckLocationOnWMS;
    end;

    procedure CheckLocationOnWMS()
    var
        DialogText: Text;
    begin
        if Type = Type::Item then begin
            DialogText := Text033;
            if "Quantity (Base)" <> 0 then
                case "Document Type" of
                    "Document Type"::Invoice:
                        if "Receipt No." = '' then
                            if Location.Get("Location Code") and Location."Directed Put-away and Pick" then begin
                                DialogText += Location.GetRequirementText(Location.FieldNo("Require Receive"));
                                Error(Text016, DialogText, FieldCaption("Line No."), "Line No.");
                            end;
                    "Document Type"::"Credit Memo":
                        if "Return Shipment No." = '' then
                            if Location.Get("Location Code") and Location."Directed Put-away and Pick" then begin
                                DialogText += Location.GetRequirementText(Location.FieldNo("Require Shipment"));
                                Error(Text016, DialogText, FieldCaption("Line No."), "Line No.");
                            end;
                end;
        end;
    end;

    procedure IsNonInventoriableItem(): Boolean
    var
        Item: Record Item;
    begin
        if Type <> Type::Item then
            exit(false);
        if "No." = '' then
            exit(false);
        GetItem(Item);
        exit(Item.IsNonInventoriableType);
    end;

    procedure IsInventoriableItem(): Boolean
    var
        Item: Record Item;
    begin
        if Type <> Type::Item then
            exit(false);
        if "No." = '' then
            exit(false);
        GetItem(Item);
        exit(Item.IsInventoriableType);
    end;

    local procedure CheckReservationForJobNo(): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        SetReservationFilters(ReservEntry);
        ReservEntry.SetRange(
          "Reservation Status", ReservEntry."Reservation Status"::Reservation, ReservEntry."Reservation Status"::Tracking);
        exit(not ReservEntry.IsEmpty);
    end;

    local procedure ValidateReturnReasonCode(CallingFieldNo: Integer)
    var
        ReturnReason: Record "Return Reason";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateReturnReasonCode(Rec, CallingFieldNo, IsHandled);
        if IsHandled then
            exit;

        if CallingFieldNo = 0 then
            exit;
        if "Return Reason Code" = '' then
            PlanPriceCalcByField(CallingFieldNo);

        if ReturnReason.Get("Return Reason Code") then begin
            if (CallingFieldNo <> FieldNo("Location Code")) and (ReturnReason."Default Location Code" <> '') then
                Validate("Location Code", ReturnReason."Default Location Code");
            if ReturnReason."Inventory Value Zero" then
                Validate("Direct Unit Cost", 0)
            else
                PlanPriceCalcByField(CallingFieldNo);
        end;
        UpdateDirectUnitCostByField(CallingFieldNo);
    end;

    [Scope('OnPrem')]
    procedure ValidateLineDiscountPercent(DropInvoiceDiscountAmount: Boolean)
    begin
        TestStatusOpen;
        GetPurchHeader;
        "Line Discount Amount" :=
          Round(
            Round(Quantity * "Direct Unit Cost", Currency."Amount Rounding Precision") *
            "Line Discount %" / 100,
            Currency."Amount Rounding Precision");
        if DropInvoiceDiscountAmount then begin
            "Inv. Discount Amount" := 0;
            "Inv. Disc. Amount to Invoice" := 0;
        end;
        UpdateAmounts;
        UpdateUnitCost;
    end;

    local procedure NotifyOnMissingSetup(FieldNumber: Integer)
    var
        DiscountNotificationMgt: Codeunit "Discount Notification Mgt.";
    begin
        if CurrFieldNo = 0 then
            exit;
        GetPurchSetup;
        DiscountNotificationMgt.RecallNotification(PurchSetup.RecordId);
        if (FieldNumber = FieldNo("Line Discount Amount")) and ("Line Discount Amount" = 0) then
            exit;
        DiscountNotificationMgt.NotifyAboutMissingSetup(
          PurchSetup.RecordId, "Gen. Bus. Posting Group", "Gen. Prod. Posting Group",
          PurchSetup."Discount Posting", PurchSetup."Discount Posting"::"Invoice Discounts");
    end;

    local procedure UpdateDimensionsFromJobTask()
    var
        SourceCodeSetup: Record "Source Code Setup";
        DimSetArrID: array[10] of Integer;
        DimValue1: Code[20];
        DimValue2: Code[20];
    begin
        SourceCodeSetup.Get();
        DimSetArrID[1] := "Dimension Set ID";
        DimSetArrID[2] :=
          DimMgt.CreateDimSetFromJobTaskDim("Job No.",
            "Job Task No.", DimValue1, DimValue2);
        DimMgt.CreateDimForPurchLineWithHigherPriorities(
          Rec, CurrFieldNo, DimSetArrID[3], DimValue1, DimValue2, SourceCodeSetup.Purchases, DATABASE::Job);

        "Dimension Set ID" :=
          DimMgt.GetCombinedDimensionSetID(
            DimSetArrID, DimValue1, DimValue2);

        "Shortcut Dimension 1 Code" := DimValue1;
        "Shortcut Dimension 2 Code" := DimValue2;
    end;

    local procedure UpdateItemCrossRef()
    begin
        DistIntegration.EnterPurchaseItemCrossRef(Rec);
        UpdateICPartner;
    end;

    local procedure UpdateItemReference()
    begin
        UpdateItemCrossRef;
        if Type <> Type::Item then
            exit;

        if "Cross-Reference No." = '' then
            SetVendorItemNo
        else
            Validate("Vendor Item No.", "Cross-Reference No.");
    end;

    local procedure UpdateICPartner()
    var
        ICPartner: Record "IC Partner";
        ItemCrossReference: Record "Item Cross Reference";
    begin
        if PurchHeader."Send IC Document" and
           (PurchHeader."IC Direction" = PurchHeader."IC Direction"::Outgoing)
        then
            case Type of
                Type::" ", Type::"Charge (Item)":
                    begin
                        "IC Partner Ref. Type" := Type.AsInteger();
                        "IC Partner Reference" := "No.";
                    end;
                Type::"G/L Account":
                    begin
                        "IC Partner Ref. Type" := Type.AsInteger();
                        "IC Partner Reference" := GLAcc."Default IC Partner G/L Acc. No";
                    end;
                Type::Item:
                    begin
                        ICPartner.Get(PurchHeader."Buy-from IC Partner Code");
                        case ICPartner."Outbound Purch. Item No. Type" of
                            ICPartner."Outbound Purch. Item No. Type"::"Common Item No.":
                                Validate("IC Partner Ref. Type", "IC Partner Ref. Type"::"Common Item No.");
                            ICPartner."Outbound Purch. Item No. Type"::"Internal No.",
                            ICPartner."Outbound Purch. Item No. Type"::"Cross Reference":
                                begin
                                    if ICPartner."Outbound Purch. Item No. Type" = ICPartner."Outbound Purch. Item No. Type"::"Internal No." then
                                        Validate("IC Partner Ref. Type", "IC Partner Ref. Type"::Item)
                                    else
                                        Validate("IC Partner Ref. Type", "IC Partner Ref. Type"::"Cross Reference");
                                    ItemCrossReference.SetRange("Cross-Reference Type", ItemCrossReference."Cross-Reference Type"::Vendor);
                                    ItemCrossReference.SetRange("Cross-Reference Type No.", "Buy-from Vendor No.");
                                    ItemCrossReference.SetRange("Item No.", "No.");
                                    ItemCrossReference.SetRange("Variant Code", "Variant Code");
                                    ItemCrossReference.SetRange("Unit of Measure", "Unit of Measure Code");
                                    if ItemCrossReference.FindFirst then
                                        "IC Partner Reference" := ItemCrossReference."Cross-Reference No."
                                    else
                                        "IC Partner Reference" := "No.";
                                end;
                            ICPartner."Outbound Purch. Item No. Type"::"Vendor Item No.":
                                begin
                                    "IC Partner Ref. Type" := "IC Partner Ref. Type"::"Vendor Item No.";
                                    "IC Partner Reference" := "Vendor Item No.";
                                end;
                        end;
                    end;
                Type::"Fixed Asset":
                    begin
                        "IC Partner Ref. Type" := "IC Partner Ref. Type"::" ";
                        "IC Partner Reference" := '';
                    end;
            end;
        OnAfterUpdateICPartner(Rec, PurchHeader);
    end;

    local procedure CalcTotalAmtToAssign(TotalQtyToAssign: Decimal) TotalAmtToAssign: Decimal
    begin
        TotalAmtToAssign := CalcLineAmount * TotalQtyToAssign / Quantity;

        if PurchHeader."Prices Including VAT" then
            TotalAmtToAssign := TotalAmtToAssign / (1 + "VAT %" / 100) - "VAT Difference";

        TotalAmtToAssign := Round(TotalAmtToAssign, Currency."Amount Rounding Precision");
    end;

    procedure HasTypeToFillMandatoryFields() ReturnValue: Boolean
    begin
        ReturnValue := Type <> Type::" ";

        OnAfterHasTypeToFillMandatoryFields(Rec, ReturnValue);
    end;

    procedure GetDeferralAmount() DeferralAmount: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDeferralAmount(Rec, DeferralAmount, IsHandled);
        if IsHandled then
            exit;

        if "VAT Base Amount" <> 0 then
            DeferralAmount := "VAT Base Amount"
        else
            DeferralAmount := CalcLineAmount;

        OnAfterGetDeferralAmount(Rec, DeferralAmount);
    end;

    local procedure UpdateDeferralAmounts()
    var
        DeferralPostDate: Date;
        AdjustStartDate: Boolean;
    begin
        GetPurchHeader;
        DeferralPostDate := PurchHeader."Posting Date";
        AdjustStartDate := true;
        if "Document Type" = "Document Type"::"Return Order" then begin
            if "Returns Deferral Start Date" = 0D then
                "Returns Deferral Start Date" := PurchHeader."Posting Date";
            DeferralPostDate := "Returns Deferral Start Date";
            AdjustStartDate := false;
        end;

        DeferralUtilities.RemoveOrSetDeferralSchedule(
          "Deferral Code", DeferralUtilities.GetPurchDeferralDocType, '', '',
          "Document Type", "Document No.", "Line No.",
          GetDeferralAmount(), DeferralPostDate, Description, PurchHeader."Currency Code", AdjustStartDate);
    end;

    procedure ShowDeferrals(PostingDate: Date; CurrencyCode: Code[10]): Boolean
    var
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDeferrals(Rec, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        exit(
            DeferralUtilities.OpenLineScheduleEdit(
                "Deferral Code", DeferralUtilities.GetPurchDeferralDocType, '', '',
                "Document Type", "Document No.", "Line No.",
                GetDeferralAmount(), PostingDate, Description, CurrencyCode));
    end;

    [Scope('OnPrem')]
    procedure InitDeferralCode()
    var
        Item: Record Item;
        Resource: Record Resource;
        GLAccount: Record "G/L Account";
    begin
        if "Document Type" in
           ["Document Type"::Order, "Document Type"::Invoice, "Document Type"::"Credit Memo", "Document Type"::"Return Order"]
        then
            case Type of
                Type::"G/L Account":
                    begin
                        GLAccount.Get("No.");
                        Validate("Deferral Code", GLAccount."Default Deferral Template Code");
                    end;
                Type::Item:
                    begin
                        GetItem(Item);
                        Validate("Deferral Code", Item."Default Deferral Template Code");
                    end;
                Type::Resource:
                    begin
                        GetResource(Resource);
                        Validate("Deferral Code", Resource."Default Deferral Template Code");
                    end;
            end;
    end;

    procedure DefaultDeferralCode()
    begin
        if Type in [Type::"G/L Account", Type::Item, Type::Resource] then
            InitDeferralCode;
    end;

    procedure IsCreditDocType(): Boolean
    begin
        exit("Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"]);
    end;

    procedure IsInvoiceDocType(): Boolean
    begin
        exit("Document Type" in ["Document Type"::Order, "Document Type"::Invoice]);
    end;

    local procedure IsReceivedFromOcr(): Boolean
    var
        IncomingDocument: Record "Incoming Document";
    begin
        GetPurchHeader;
        if not IncomingDocument.Get(PurchHeader."Incoming Document Entry No.") then
            exit(false);
        exit(IncomingDocument."OCR Status" = IncomingDocument."OCR Status"::Success);
    end;

    local procedure TestReturnFieldsZero()
    begin
        TestField("Return Qty. Shipped Not Invd.", 0);
        TestField("Return Qty. Shipped", 0);
        TestField("Return Shipment No.", '');
    end;

    procedure CanEditUnitOfMeasureCode(): Boolean
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        if (Type = Type::Item) and ("No." <> '') then begin
            ItemUnitOfMeasure.SetRange("Item No.", "No.");
            exit(ItemUnitOfMeasure.Count > 1);
        end;
        exit(true);
    end;

    procedure TestItemFields(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
        TestField(Type, Type::Item);
        TestField("No.", ItemNo);
        TestField("Variant Code", VariantCode);
        TestField("Location Code", LocationCode);
    end;

    procedure ClearPurchaseHeader()
    begin
        Clear(PurchHeader);
    end;

    local procedure GetBlockedItemNotificationID(): Guid
    begin
        exit('963A9FD3-11E8-4CAA-BE3A-7F8CEC9EF8EC');
    end;

    local procedure SendBlockedItemNotification()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NotificationToSend: Notification;
    begin
        NotificationToSend.Id := GetBlockedItemNotificationID;
        NotificationToSend.Recall;
        NotificationToSend.Message := StrSubstNo(BlockedItemNotificationMsg, "No.");
        NotificationLifecycleMgt.SendNotification(NotificationToSend, RecordId);
    end;

    procedure SendLineInvoiceDiscountResetNotification()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NotificationToSend: Notification;
    begin
        if ("Inv. Discount Amount" = 0) and (xRec."Inv. Discount Amount" <> 0) and ("Line Amount" <> 0) then begin
            NotificationToSend.Id := PurchHeader.GetLineInvoiceDiscountResetNotificationId;
            NotificationToSend.Message := StrSubstNo(LineInvoiceDiscountAmountResetTok, RecordId);

            NotificationLifecycleMgt.SendNotification(NotificationToSend, RecordId);
        end;
    end;

    procedure FormatType() FormattedType: Text[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFormatType(Rec, FormattedType, IsHandled);
        If IsHandled then
            exit(FormattedType);

        if Type = Type::" " then
            exit(CommentLbl);

        exit(Format(Type));
    end;

    procedure RenameNo(LineType: Option; OldNo: Code[20]; NewNo: Code[20])
    begin
        Reset;
        SetRange(Type, LineType);
        SetRange("No.", OldNo);
        ModifyAll("No.", NewNo, true);
    end;

    local procedure UpdateLineDiscPct()
    var
        LineDiscountPct: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateLineDiscPct(Rec, Currency, IsHandled);
        if IsHandled then
            exit;

        if Round(Quantity * "Direct Unit Cost", Currency."Amount Rounding Precision") <> 0 then begin
            LineDiscountPct := Round(
                "Line Discount Amount" / Round(Quantity * "Direct Unit Cost", Currency."Amount Rounding Precision") * 100,
                0.00001);
            if not (LineDiscountPct in [0 .. 100]) then
                Error(LineDiscountPctErr);
            "Line Discount %" := LineDiscountPct;
        end else
            "Line Discount %" := 0;
    end;

    local procedure UpdateBaseAmounts(NewAmount: Decimal; NewAmountIncludingVAT: Decimal; NewVATBaseAmount: Decimal)
    begin
        Amount := NewAmount;
        "Amount Including VAT" := NewAmountIncludingVAT;
        "VAT Base Amount" := NewVATBaseAmount;
        if not PurchHeader."Prices Including VAT" and (Amount > 0) and (Amount < "Prepmt. Line Amount") then
            "Prepmt. Line Amount" := Amount;
        if PurchHeader."Prices Including VAT" and ("Amount Including VAT" > 0) and ("Amount Including VAT" < "Prepmt. Line Amount") then
            "Prepmt. Line Amount" := "Amount Including VAT";

        OnAfterUpdateBaseAmounts(Rec, xRec, CurrFieldNo);
    end;

    local procedure UpdatePrepmtAmounts()
    var
        RemLineAmountToInvoice: Decimal;
    begin
        if "Prepayment %" <> 0 then begin
            if Quantity < 0 then
                FieldError(Quantity, StrSubstNo(Text043, FieldCaption("Prepayment %")));
            if "Direct Unit Cost" < 0 then
                FieldError("Direct Unit Cost", StrSubstNo(Text043, FieldCaption("Prepayment %")));
        end;
        if PurchHeader."Document Type" <> PurchHeader."Document Type"::Invoice then begin
            "Prepayment VAT Difference" := 0;
            if not PrePaymentLineAmountEntered then
                "Prepmt. Line Amount" := Round("Line Amount" * "Prepayment %" / 100, Currency."Amount Rounding Precision");
            if "Prepmt. Line Amount" < "Prepmt. Amt. Inv." then begin
                if IsServiceCharge() then
                    Error(CannotChangePrepaidServiceChargeErr);
                FieldError("Prepmt. Line Amount", StrSubstNo(Text037, "Prepmt. Amt. Inv."));
            end;
            PrePaymentLineAmountEntered := false;
            if "Prepmt. Line Amount" <> 0 then begin
                RemLineAmountToInvoice :=
                  Round("Line Amount" * (Quantity - "Quantity Invoiced") / Quantity, Currency."Amount Rounding Precision");
                if RemLineAmountToInvoice < ("Prepmt. Line Amount" - "Prepmt Amt Deducted") then
                    FieldError("Prepmt. Line Amount", StrSubstNo(Text039, RemLineAmountToInvoice + "Prepmt Amt Deducted"));
            end;
        end else
            if (CurrFieldNo <> 0) and ("Line Amount" <> xRec."Line Amount") and
               ("Prepmt. Amt. Inv." <> 0) and ("Prepayment %" = 100)
            then begin
                if "Line Amount" < xRec."Line Amount" then
                    FieldError("Line Amount", StrSubstNo(Text038, xRec."Line Amount"));
                FieldError("Line Amount", StrSubstNo(Text039, xRec."Line Amount"));
            end;
    end;

    local procedure IsCalcVATAmountLinesHandled(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line") IsHandled: Boolean
    begin
        IsHandled := false;
        OnBeforeCalcVATAmountLines(PurchHeader, PurchLine, VATAmountLine, IsHandled);
        exit(IsHandled);
    end;

    local procedure OverReceiptProcessing(): Boolean
    var
        OverReceiptMgt: Codeunit "Over-Receipt Mgt.";
    begin
        if not OverReceiptMgt.IsOverReceiptAllowed() or (CurrFieldNo <> FieldNo("Qty. to Receive")) or (Abs("Qty. to Receive") <= Abs("Outstanding Quantity")) then
            exit(false);

        Validate("Over-Receipt Quantity", "Qty. to Receive" - xRec."Qty. to Receive");
        exit(true);
    end;

    local procedure GetResource(var Resource: Record Resource)
    begin
        TestField("No.");
        Resource.Get("No.")
    end;

    local procedure CopyFromResource()
    var
        Resource: Record Resource;
    begin
        GetResource(Resource);
        Resource.CheckResourcePrivacyBlocked(false);
        Resource.TestField(Blocked, false);
        Resource.TestField("Gen. Prod. Posting Group");
        Description := Resource.Name;
        "Description 2" := Resource."Name 2";
        "Unit of Measure Code" := Resource."Base Unit of Measure";
        "Gen. Prod. Posting Group" := Resource."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := Resource."VAT Prod. Posting Group";
        "Tax Group Code" := Resource."Tax Group Code";
        "Allow Item Charge Assignment" := false;
        "Direct Unit Cost" := Resource."Direct Unit Cost";
        InitDeferralCode();

        OnAfterAssignResourceValues(Rec, Resource);
    end;

    local procedure CheckBuyFromVendorNo(PurchaseHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBuyFromVendorNo(PurchaseHeader, IsHandled);
        if IsHandled then
            exit;

        PurchaseHeader.TestField("Buy-from Vendor No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddItem(var PurchaseLine: Record "Purchase Line"; LastPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignFieldsForNo(var PurchLine: Record "Purchase Line"; var xPurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignHeaderValues(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignStdTxtValues(var PurchLine: Record "Purchase Line"; StandardText: Record "Standard Text")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignGLAccountValues(var PurchLine: Record "Purchase Line"; GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignItemValues(var PurchLine: Record "Purchase Line"; Item: Record Item; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignItemChargeValues(var PurchLine: Record "Purchase Line"; ItemCharge: Record "Item Charge")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignFixedAssetValues(var PurchLine: Record "Purchase Line"; FixedAsset: Record "Fixed Asset")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignItemUOM(var PurchLine: Record "Purchase Line"; Item: Record Item; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBlanketOrderLookup(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteChargeChargeAssgnt(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDeferralAmount(PurchaseLine: Record "Purchase Line"; var DeferralAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItem(var Item: Record Item; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItemTranslation(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; ItemTranslation: Record "Item Translation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPurchHeader(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPurchSetup(var PurchaseLine: Record "Purchase Line"; var PurchSetup: Record "Purchases & Payables Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetFAPostingGroup(var PurchaseLine: Record "Purchase Line"; GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesWithItemToPlan(var PurchaseLine: Record "Purchase Line"; var Item: Record Item; DocumentType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasTypeToFillMandatoryFields(var PurchaseLine: Record "Purchase Line"; var ReturnValue: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitType(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDirectUnitCost(var PurchLine: Record "Purchase Line"; xPurchLine: Record "Purchase Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDirectUnitCost(var PurchLine: Record "Purchase Line"; xPurchLine: Record "Purchase Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyReservedQty(var PurchLine: Record "Purchase Line"; xPurchLine: Record "Purchase Line"; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitHeaderDefaults(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitOutstandingQty(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitOutstandingAmount(var PurchLine: Record "Purchase Line"; xPurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToInvoice(var PurchLine: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToShip(var PurchLine: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToReceive(var PurchLine: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToReceive2(var PurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToReceive2Procedure(var PurchLine: Record "Purchase Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDefaultQuantity(var PurchLine: Record "Purchase Line"; var xPurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLineAmount(var PurchaseLine: Record "Purchase Line"; var LineAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcVATAmountLines(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line"; QtyType: Option General,Invoicing,Shipping)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckReceiptRelation(PurchaseLine: Record "Purchase Line"; PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckRetShptRelation(var PurchaseLine: Record "Purchase Line"; ReturnShipmentLine: Record "Return Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var PurchLine: Record "Purchase Line"; CallingFieldNo: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var PurchLine: Record "Purchase Line"; CallingFieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLineAmountToHandle(PurchLine: Record "Purchase Line"; QtyToHandle: Decimal; var LineAmount: Decimal; var LineDiscAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesTaxCalculate(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesTaxCalculateReverse(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestStatusOpen(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDates(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAmounts(var PurchLine: Record "Purchase Line"; var xPurchLine: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAmountsDone(var PurchLine: Record "Purchase Line"; var xPurchLine: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateBaseAmounts(var PurchLine: Record "Purchase Line"; var xPurchLine: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateUnitCost(var PurchLine: Record "Purchase Line"; xPurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; Item: Record Item; StockkeepingUnit: Record "Stockkeeping Unit"; Currency: Record Currency; GLSetup: Record "General Ledger Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateICPartner(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateJobPrices(var PurchLine: Record "Purchase Line"; JobJnlLine: Record "Job Journal Line"; PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateWithWarehouseReceive(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVATAmounts(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVATOnLines(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line"; QtyType: Option General,Invoicing,Shipping)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSalesCost(var PurchaseLine: Record "Purchase Line"; var SalesOrderLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateTotalAmounts(var PurchaseLine: Record "Purchase Line"; PurchaseLine2: Record "Purchase Line"; var TotalAmount: Decimal; var TotalAmountInclVAT: Decimal; var TotalLineAmount: Decimal; var TotalInvDiscAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateCrossReferenceNo(PurchaseLine: Record "Purchase Line"; ItemCrossReference: Record "Item Cross Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddItems(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignHeaderValues(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPrepaymentToDeduct(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearQtyIfBlank(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAssosiatedSalesOrder(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAssosiatedProdOrder(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWarehouse(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromItem(var PurchaseLine: Record "Purchase Line"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBlanketOrderLookup(var PurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvDiscToInvoice(var PurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcVATAmountLines(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTempJobJnlLine(var TempJobJournalLine: Record "Job Journal Line" temporary; PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; GetPrices: Boolean; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultBin(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDeferralAmount(var PurchaseLine: Record "Purchase Line"; var DeferralAmount: Decimal; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItemTranslation(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetFAPostingGroup(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFormatType(PurchaseLine: Record "Purchase Line"; var FormattedType: Text[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitQtyToInvoice(var PurchaseLine: Record "Purchase Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitQtyToReceive(var PurchaseLine: Record "Purchase Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitQtyToShip(var PurchaseLine: Record "Purchase Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobSetCurrencyFactor(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobTaskIsSet(PurchLine: Record "Purchase Line"; var IsJobLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMaxQtyToInvoice(PurchaseLine: Record "Purchase Line"; var MaxQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMaxQtyToInvoiceBase(PurchaseLine: Record "Purchase Line"; var MaxQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenItemTrackingLines(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDeferrals(PurchaseLine: Record "Purchase Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowReservation(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowReservationEntries(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestStatusOpen(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDates(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateLeadTimeFields(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateLineDiscPct(var PurchaseLine: Record "Purchase Line"; Currency: Record Currency; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePrepmtAmounts(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePrepmtSetupFields(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAmounts(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVATAmounts(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesCost(var PurchaseLine: Record "Purchase Line"; var SalesOrderLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitCost(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateWithWarehouseReceive(var PurchaseLine: Record "Purchase Line"; var InHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDescription(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var InHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePromisedReceiptDate(var PurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateReturnReasonCode(var PurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTempJobJnlLine(var JobJournalLine: Record "Job Journal Line"; PurchLine: Record "Purchase Line"; xPurchLine: Record "Purchase Line"; GetPrices: Boolean; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnAfterCalcLineTotals(var VATAmountLine: Record "VAT Amount Line"; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; Currency: Record Currency; QtyType: Option General,Invoicing,Shipping; var TotalVATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnAfterSetFilters(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromItemOnAfterCheck(PurchaseLine: Record "Purchase Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCrossReferenceNoLookUpOnAfterSetFilters(var ItemCrossReference: Record "Item Cross Reference"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCrossReferenceNoLookupOnBeforeValidateDirectUnitCost(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnAfterSetPurchLineFilters(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFilterLinesForReservationOnBeforeSetFilterVariantCode(var PurchaseLine: Record "Purchase Line"; var ReservationEntry: Record "Reservation Entry"; var Positive: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitQtyToReceive2OnBeforeCalcInvDiscToInvoice(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowItemChargeAssgntOnBeforeCalcItemCharge(var PurchaseLine: Record "Purchase Line"; var ItemChargeAssgntLineAmt: Decimal; Currency: Record Currency; var IsHandled: Boolean; var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDirectUnitCostOnBeforeFindPrice(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; CalledByFieldNo: Integer; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnBeforeUpdateUnitCostLCY(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; CurrentFieldNo: Integer; Item: Record Item; SKU: Record "Stockkeeping Unit"; Currency: Record Currency; GLSetup: Record "General Ledger Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterSetFilters(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterCalculateAmounts(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnBeforeCalculateAmounts(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCrossReferenceNoOnBeforeAssignNo(var PurchaseLine: Record "Purchase Line"; var ItemCrossReference: Record "Item Cross Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateExpectedReceiptDateOnBeforeCheckDateConflict(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLocationCodeOnBeforeDropShipmentError(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLocationCodeOnBeforeSpecialOrderError(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateTypeOnAfterCheckItem(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateTypeOnCopyFromTempPurchLine(var PurchLine: Record "Purchase Line"; TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnCopyFromTempPurchLine(var PurchLine: Record "Purchase Line"; TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnAfterAssignQtyFromXRec(var PurchaseLine: Record "Purchase Line"; TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnAfterChecks(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnAfterVerifyChange(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnBeforeInitRec(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePurchasingCodeOnAfterAssignFields(var PurchaseLine: Record "Purchase Line"; Purchasing: Record Purchasing)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToReceiveOnAfterCheck(var PurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToReceiveOnAfterInitQty(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToReceiveOnBeforeInitQtyToReceive(var PurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeDropShptCheck(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeInitQtyToReceive(var PurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateReturnQtyToShipOnAfterCheck(var PurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateReturnQtyToShipOnAfterInitQty(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitCostLCYOnAfterUpdateUnitCostCurrency(var PurchaseLine: Record "Purchase Line"; var UnitCostCurrency: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitOfMeasureCodeOnBeforeDropShipmentError(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVariantCodeOnAfterValidationChecks(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVariantCodeOnBeforeDropShipmentError(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnAfterVATPostingSetupGet(var VATPostingSetup: Record "VAT Posting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnBeforeCheckVATCalcType(var PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateOverReceiptQuantity(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CalledByFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    procedure AssignedItemCharge(): Boolean
    begin
        exit((Type = Type::"Charge (Item)") and ("No." <> '') and ("Qty. to Assign" < Quantity));
    end;

    [Obsolete('Function scope will be changed to OnPrem', '15.1')]
    procedure ShowDeferralSchedule()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get("Document Type", "Document No.");
        ShowDeferrals(PurchaseHeader."Posting Date", PurchaseHeader."Currency Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignResourceValues(var PurchaseLine: Record "Purchase Line"; Resource: Record Resource)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignResourceUOM(var PurchaseLine: Record "Purchase Line"; Resource: Record Resource; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBlanketOrderNoOnAfterCheck(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBuyFromVendorNo(PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInternalLeadTimeDays(PurchaseLine: Record "Purchase Line"; PurchDate: Date; TotalDays: DateFormula);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPurchHeader(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; var Currency: Record Currency)
    begin
    end;
}

