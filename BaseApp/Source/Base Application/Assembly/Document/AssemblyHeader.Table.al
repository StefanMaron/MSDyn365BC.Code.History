﻿namespace Microsoft.Assembly.Document;

using Microsoft.Assembly.Comment;
using Microsoft.Assembly.Setup;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;
using System.Security.User;
using System.Utilities;

table 900 "Assembly Header"
{
    Caption = 'Assembly Header';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "Assembly List";
    LookupPageID = "Assembly List";
    Permissions = TableData "Assembly Line" = d;

    fields
    {
        field(1; "Document Type"; Enum "Assembly Document Type")
        {
            Caption = 'Document Type';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;

            trigger OnValidate()
            var
                NoSeriesMgt: Codeunit NoSeriesManagement;
            begin
                TestStatusOpen();
                if "No." <> xRec."No." then begin
                    AssemblySetup.Get();
                    NoSeriesMgt.TestManual(GetNoSeriesCode());
                    "No. Series" := '';
                end;
            end;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                "Search Description" := Description;
            end;
        }
        field(4; "Search Description"; Code[100])
        {
            Caption = 'Search Description';
        }
        field(5; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(6; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            Editable = false;
        }
        field(7; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(10; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item where(Type = const(Inventory));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                CheckIsNotAsmToOrder();
                TestStatusOpen();
                SetCurrentFieldNum(FieldNo("Item No."));

                if "Item No." <> xRec."Item No." then
                    "Variant Code" := '';

                if "Item No." <> '' then begin
                    SetDescriptionsFromItem();
                    Item.TestField(Blocked, false);
                    "Unit Cost" := GetUnitCost();
                    "Overhead Rate" := Item."Overhead Rate";
                    "Inventory Posting Group" := Item."Inventory Posting Group";
                    "Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
                    "Indirect Cost %" := Item."Indirect Cost %";
                    Validate("Unit of Measure Code", Item."Base Unit of Measure");
                    CreateDimFromDefaultDim();
                    IsHandled := false;
                    OnValidateItemNoOnBeforeValidateDates(Rec, xRec, IsHandled);
                    if not IsHandled then
                        ValidateDates(FieldNo("Due Date"), true);
                    GetDefaultBin();
                    OnValidateItemNoOnAfterGetDefaultBin(Rec, Item);
                end;
                AssemblyLineMgt.UpdateAssemblyLines(Rec, xRec, FieldNo("Item No."), true, CurrFieldNo, CurrentFieldNum);
                AssemblyHeaderReserve.VerifyChange(Rec, xRec);
                ClearCurrentFieldNum(FieldNo("Item No."));
            end;
        }
        field(12; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."),
                                                       Code = field("Variant Code"));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
                IsHandled: Boolean;
            begin
                CheckIsNotAsmToOrder();
                TestStatusOpen();
                SetCurrentFieldNum(FieldNo("Variant Code"));
                if Rec."Variant Code" = '' then
                    SetDescriptionsFromItem()
                else begin
                    ItemVariant.SetLoadFields(Description, "Description 2", Blocked);
                    ItemVariant.Get("Item No.", "Variant Code");
                    ItemVariant.TestField(Blocked, false);
                    Description := ItemVariant.Description;
                    "Description 2" := ItemVariant."Description 2";
                end;
                IsHandled := false;
                OnValidateVariantCodeOnBeforeValidateDates(Rec, xRec, IsHandled);
                if not IsHandled then
                    ValidateDates(FieldNo("Due Date"), true);

                IsHandled := false;
                OnValidateVariantCodeOnBeforeUpdateAssemblyLines(Rec, xRec, CurrFieldNo, CurrentFieldNum, IsHandled);
                if not IsHandled then
                    AssemblyLineMgt.UpdateAssemblyLines(Rec, xRec, FieldNo("Variant Code"), false, CurrFieldNo, CurrentFieldNum);
                AssemblyHeaderReserve.VerifyChange(Rec, xRec);
                GetDefaultBin();
                Validate("Unit Cost", GetUnitCost());
                ClearCurrentFieldNum(FieldNo("Variant Code"));
            end;
        }
        field(15; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";
        }
        field(16; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(19; Comment; Boolean)
        {
            CalcFormula = exist("Assembly Comment Line" where("Document Type" = field("Document Type"),
                                                               "Document No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                CheckIsNotAsmToOrder();
                TestStatusOpen();
                SetCurrentFieldNum(FieldNo("Location Code"));
                IsHandled := false;
                OnValidateLocationCodeOnBeforeValidateDates(Rec, xRec, IsHandled);
                if not IsHandled then
                    ValidateDates(FieldNo("Due Date"), true);
                AssemblyLineMgt.UpdateAssemblyLines(Rec, xRec, FieldNo("Location Code"), false, CurrFieldNo, CurrentFieldNum);
                AssemblyHeaderReserve.VerifyChange(Rec, xRec);
                GetDefaultBin();
                Validate("Unit Cost", GetUnitCost());
                ClearCurrentFieldNum(FieldNo("Location Code"));
                CreateDimFromDefaultDim();
            end;
        }
        field(21; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(22; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(23; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            var
                ATOLink: Record "Assemble-to-Order Link";
                SalesHeader: Record "Sales Header";
            begin
                if ATOLink.Get("Document Type", "No.") and (CurrFieldNo = FieldNo("Posting Date")) then
                    if SalesHeader.Get(ATOLink."Document Type", ATOLink."Document No.") and ("Posting Date" > SalesHeader."Posting Date") then
                        Error(PostingDateLaterErr, "No.", SalesHeader."No.");
            end;
        }
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';

            trigger OnValidate()
            begin
                ValidateDueDate("Due Date", true);
            end;
        }
        field(25; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                ValidateStartDate("Starting Date", true);
            end;
        }
        field(27; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                ValidateEndDate("Ending Date", true);
            end;
        }
        field(33; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = if (Quantity = filter(< 0)) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"),
                                                                                     "Item No." = field("Item No."),
                                                                                     "Variant Code" = field("Variant Code"))
            else
            Bin.Code where("Location Code" = field("Location Code"));

            trigger OnLookup()
            var
                WMSManagement: Codeunit "WMS Management";
                BinCode: Code[20];
            begin
                if Quantity < 0 then
                    BinCode := WMSManagement.BinContentLookUp("Location Code", "Item No.", "Variant Code", '', "Bin Code")
                else
                    BinCode := WMSManagement.BinLookUp("Location Code", "Item No.", "Variant Code", '');

                if BinCode <> '' then
                    Validate("Bin Code", BinCode);
            end;

            trigger OnValidate()
            begin
                CheckIsNotAsmToOrder(Rec.FieldNo("Bin Code"));
                ValidateBinCode("Bin Code");
            end;
        }
        field(40; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                UOMMgt: Codeunit "Unit of Measure Management";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQuantity(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                CheckIsNotAsmToOrder();
                TestStatusOpen();

                SetCurrentFieldNum(FieldNo(Quantity));

                Quantity := UOMMgt.RoundAndValidateQty(Quantity, "Qty. Rounding Precision", FieldCaption(Quantity));

                "Cost Amount" := Round(Quantity * "Unit Cost");
                if Quantity < "Assembled Quantity" then
                    Error(Text002, FieldCaption(Quantity), FieldCaption("Assembled Quantity"), "Assembled Quantity");

                "Quantity (Base)" := CalcBaseQty(Quantity, FieldCaption("Quantity (Base)"), FieldCaption(Quantity));
                OnValiateQuantityOnAfterCalcBaseQty(Rec, CurrFieldNo);
                InitRemainingQty();
                InitQtyToAssemble();
                Validate("Quantity to Assemble");

                UpdateAssemblyLinesAndVerifyReserveQuantity();

                ClearCurrentFieldNum(FieldNo(Quantity));
            end;
        }
        field(41; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQuantityBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();
                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Quantity (Base)");
            end;
        }
        field(42; "Remaining Quantity"; Decimal)
        {
            Caption = 'Remaining Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(43; "Remaining Quantity (Base)"; Decimal)
        {
            Caption = 'Remaining Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(44; "Assembled Quantity"; Decimal)
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'Assembled Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(45; "Assembled Quantity (Base)"; Decimal)
        {
            Caption = 'Assembled Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(46; "Quantity to Assemble"; Decimal)
        {
            Caption = 'Quantity to Assemble';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                ATOLink: Record "Assemble-to-Order Link";
                UOMMgt: Codeunit "Unit of Measure Management";
            begin
                SetCurrentFieldNum(FieldNo("Quantity to Assemble"));

                "Quantity to Assemble" := UOMMgt.RoundAndValidateQty("Quantity to Assemble", "Qty. Rounding Precision", FieldCaption("Quantity to Assemble"));
                if "Quantity to Assemble" > "Remaining Quantity" then
                    Error(Text003,
                      FieldCaption("Quantity to Assemble"), FieldCaption("Remaining Quantity"), "Remaining Quantity");

                if "Quantity to Assemble" <> xRec."Quantity to Assemble" then
                    ATOLink.CheckQtyToAsm(Rec);

                Validate(
                    "Quantity to Assemble (Base)",
                    CalcBaseQty("Quantity to Assemble", FieldCaption("Quantity to Assemble (Base)"), FieldCaption("Quantity to Assemble"))
                );

                AssemblyLineMgt.UpdateAssemblyLines(Rec, xRec, FieldNo("Quantity to Assemble"), false, CurrFieldNo, CurrentFieldNum);
                ClearCurrentFieldNum(FieldNo("Quantity to Assemble"));
            end;
        }
        field(47; "Quantity to Assemble (Base)"; Decimal)
        {
            Caption = 'Quantity to Assemble (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(48; "Reserved Quantity"; Decimal)
        {
            CalcFormula = sum("Reservation Entry".Quantity where("Source ID" = field("No."),
                                                                  "Source Type" = const(900),
#pragma warning disable AL0603
                                                                  "Source Subtype" = field("Document Type"),
#pragma warning restore
                                                                  "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(49; "Reserved Qty. (Base)"; Decimal)
        {
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Source ID" = field("No."),
                                                                           "Source Type" = const(900),
#pragma warning disable AL0603
                                                                           "Source Subtype" = field("Document Type"),
#pragma warning restore
                                                                           "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(50; "Planning Flexibility"; Enum "Reservation Planning Flexibility")
        {
            Caption = 'Planning Flexibility';

            trigger OnValidate()
            begin
                CheckIsNotAsmToOrder();
                TestStatusOpen();
                if "Planning Flexibility" <> xRec."Planning Flexibility" then
                    AssemblyHeaderReserve.UpdatePlanningFlexibility(Rec);
            end;
        }
        field(51; "MPS Order"; Boolean)
        {
            Caption = 'MPS Order';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(54; "Assemble to Order"; Boolean)
        {
            CalcFormula = exist("Assemble-to-Order Link" where("Assembly Document Type" = field("Document Type"),
                                                                "Assembly Document No." = field("No.")));
            Caption = 'Assemble to Order';
            Editable = false;
            FieldClass = FlowField;
        }
        field(63; "Posting No."; Code[20])
        {
            Caption = 'Posting No.';
            Editable = false;
        }
        field(65; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            MinValue = 0;

            trigger OnValidate()
            var
                SkuItemUnitCost: Decimal;
            begin
                if "Item No." <> '' then begin
                    GetItem();

                    if Item."Costing Method" = Item."Costing Method"::Standard then begin
                        SkuItemUnitCost := GetUnitCost();
                        if "Unit Cost" <> SkuItemUnitCost then
                            Error(Text005,
                              FieldCaption("Unit Cost"),
                              FieldCaption("Cost Amount"),
                              Item.FieldCaption("Costing Method"),
                              Item."Costing Method");
                    end;
                end;

                "Cost Amount" := Round(Quantity * "Unit Cost");
            end;
        }
        field(67; "Cost Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Cost Amount';
            Editable = false;
        }
        field(68; "Rolled-up Assembly Cost"; Decimal)
        {
            CalcFormula = sum("Assembly Line"."Cost Amount" where("Document Type" = field("Document Type"),
                                                                   "Document No." = field("No."),
                                                                   Type = filter(Item | Resource)));
            Caption = 'Rolled-up Assembly Cost';
            FieldClass = FlowField;
        }
        field(75; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;
        }
        field(76; "Overhead Rate"; Decimal)
        {
            Caption = 'Overhead Rate';
            DecimalPlaces = 0 : 5;
        }
        field(80; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            var
                UOMMgt: Codeunit "Unit of Measure Management";
            begin
                CheckIsNotAsmToOrder();
                TestField("Assembled Quantity", 0);
                TestStatusOpen();
                SetCurrentFieldNum(FieldNo("Unit of Measure Code"));

                GetItem();
                "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                "Qty. Rounding Precision" := UOMMgt.GetQtyRoundingPrecision(Item, "Unit of Measure Code");
                "Qty. Rounding Precision (Base)" := UOMMgt.GetQtyRoundingPrecision(Item, Item."Base Unit of Measure");
                "Unit Cost" := GetUnitCost();
                "Overhead Rate" := Item."Overhead Rate";

                AssemblyLineMgt.UpdateAssemblyLines(Rec, xRec, FieldNo("Unit of Measure Code"), ReplaceLinesFromBOM(), CurrFieldNo, CurrentFieldNum);
                ClearCurrentFieldNum(FieldNo("Unit of Measure Code"));

                Validate(Quantity);
            end;
        }
        field(81; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                CheckIsNotAsmToOrder();
                TestStatusOpen();
            end;
        }
        field(82; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(83; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(108; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            var
                AsmHeader: Record "Assembly Header";
                NoSeriesMgt: Codeunit NoSeriesManagement;
            begin
                AsmHeader := Rec;
                AssemblySetup.Get();
                TestNoSeries();
                if NoSeriesMgt.LookupSeries(GetPostingNoSeriesCode(), AsmHeader."Posting No. Series") then
                    AsmHeader.Validate("Posting No. Series");
                Rec := AsmHeader;
            end;

            trigger OnValidate()
            var
                NoSeriesMgt: Codeunit NoSeriesManagement;
            begin
                TestStatusOpen();
                if "Posting No. Series" <> '' then begin
                    AssemblySetup.Get();
                    TestNoSeries();
                    NoSeriesMgt.TestSeries(GetPostingNoSeriesCode(), "Posting No. Series");
                end;
                TestField("Posting No.", '');
            end;
        }
        field(120; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;

            trigger OnValidate()
            var
                DimMgt: Codeunit DimensionManagement;
            begin
                SetCurrentFieldNum(FieldNo("Dimension Set ID"));
                if "Dimension Set ID" <> xRec."Dimension Set ID" then begin
                    AssemblyLineMgt.SetHideValidationDialog(HideValidationDialog);
                    AssemblyLineMgt.UpdateAssemblyLines(Rec, xRec, FieldNo("Dimension Set ID"), false, CurrFieldNo, CurrentFieldNum);
                end;
                ClearCurrentFieldNum(FieldNo("Dimension Set ID"));
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(9000; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";
        }
        field(11700; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to Advanced Localization Pack for Czech.';
            ObsoleteTag = '21.0';
        }
    }

    keys
    {
        key(Key1; "Document Type", "No.")
        {
            Clustered = true;
        }
        key(Key2; "Document Type", "Item No.", "Variant Code", "Location Code", "Due Date")
        {
            IncludedFields = "Remaining Quantity (Base)";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CheckIsNotAsmToOrder();

        AssemblyHeaderReserve.DeleteLine(Rec);
        CalcFields("Reserved Qty. (Base)");
        TestField("Reserved Qty. (Base)", 0);

        DeleteAssemblyLines();
    end;

    trigger OnInsert()
    var
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        CheckIsNotAsmToOrder();

        AssemblySetup.Get();

        if "No." = '' then begin
            TestNoSeries();
            NoSeriesMgt.InitSeries(GetNoSeriesCode(), xRec."No. Series", "Posting Date", "No.", "No. Series");
        end;

        if "Document Type" = "Document Type"::Order then begin
            InvtAdjmtEntryOrder.SetRange("Order Type", InvtAdjmtEntryOrder."Order Type"::Assembly);
            InvtAdjmtEntryOrder.SetRange("Order No.", "No.");
            if not InvtAdjmtEntryOrder.IsEmpty() then
                Error(Text001, Format("Document Type"), "No.");
        end;

        InitRecord();

        if GetFilter("Item No.") <> '' then
            if GetRangeMin("Item No.") = GetRangeMax("Item No.") then
                Validate("Item No.", GetRangeMin("Item No."));
    end;

    trigger OnModify()
    begin
        AssemblyHeaderReserve.VerifyChange(Rec, xRec);
    end;

    trigger OnRename()
    begin
        Error(Text009, TableCaption);
    end;

    var
        AssemblySetup: Record "Assembly Setup";
        Item: Record Item;
        GLSetup: Record "General Ledger Setup";
        StockkeepingUnit: Record "Stockkeeping Unit";
        AssemblyHeaderReserve: Codeunit "Assembly Header-Reserve";
        AssemblyLineMgt: Codeunit "Assembly Line Management";
        ConfirmManagement: Codeunit "Confirm Management";
        GLSetupRead: Boolean;
        CurrentFieldNum: Integer;
        PostingDateLaterErr: Label 'Posting Date on Assembly Order %1 must not be later than the Posting Date on Sales Order %2.';
        RowIdx: Option ,MatCost,ResCost,ResOvhd,AsmOvhd,Total;

        Text001: Label '%1 %2 cannot be created, because it already exists or has been posted.', Comment = '%1 = Document Type, %2 = No.';
        Text002: Label '%1 cannot be lower than the %2, which is %3.';
        Text003: Label '%1 cannot be higher than the %2, which is %3.';
        Text005: Label 'Changing %1 or %2 is not allowed when %3 is %4.';
        Text007: Label 'Nothing to handle. The assembly line items are completely picked.';
        Text009: Label 'You cannot rename an %1.';
        Text010: Label 'You have modified %1.';
        Text011: Label 'the %1 from %2 to %3';
        Text012: Label '%1 %2', Locked = true;
        Text013: Label 'Do you want to update %1?';
        Text014: Label '%1 and %2';
        Text015: Label '%1 %2 is before %3 %4.', Comment = '%1 and %3 = Date Captions, %2 and %4 = Date Values';
        UpdateDimensionLineMsg: Label 'You may have changed a dimension.\\Do you want to update the lines?';

    protected var
        StatusCheckSuspended: Boolean;
        TestReservationDateConflict: Boolean;
        HideValidationDialog: Boolean;


    [Scope('OnPrem')]
    procedure RefreshBOM()
    begin
        AssemblyLineMgt.UpdateAssemblyLines(Rec, xRec, 0, true, CurrFieldNo, 0);
    end;

    procedure InitRecord()
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        case "Document Type" of
            "Document Type"::Quote, "Document Type"::"Blanket Order":
                NoSeriesMgt.SetDefaultSeries("Posting No. Series", AssemblySetup."Posted Assembly Order Nos.");
            "Document Type"::Order:
                if ("No. Series" <> '') and
                    (AssemblySetup."Assembly Order Nos." = AssemblySetup."Posted Assembly Order Nos.")
                then
                    "Posting No. Series" := "No. Series"
                else
                    NoSeriesMgt.SetDefaultSeries("Posting No. Series", AssemblySetup."Posted Assembly Order Nos.");
        end;

        "Creation Date" := WorkDate();
        if "Due Date" = 0D then
            "Due Date" := WorkDate();
        "Posting Date" := WorkDate();
        if "Starting Date" = 0D then
            "Starting Date" := WorkDate();
        if "Ending Date" = 0D then
            "Ending Date" := WorkDate();

        SetDefaultLocation();

        OnAfterInitRecord(Rec);
    end;

    procedure InitRemainingQty()
    begin
        "Remaining Quantity" := Quantity - "Assembled Quantity";
        "Remaining Quantity (Base)" := "Quantity (Base)" - "Assembled Quantity (Base)";

        OnAfterInitRemaining(Rec, CurrFieldNo);
    end;

    procedure InitQtyToAssemble()
    var
        ATOLink: Record "Assemble-to-Order Link";
    begin
        "Quantity to Assemble" := "Remaining Quantity";
        "Quantity to Assemble (Base)" := "Remaining Quantity (Base)";
        ATOLink.InitQtyToAsm(Rec, "Quantity to Assemble", "Quantity to Assemble (Base)");

        OnAfterInitQtyToAssemble(Rec, CurrFieldNo);
    end;

    procedure AssistEdit(OldAssemblyHeader: Record "Assembly Header"): Boolean
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyHeader2: Record "Assembly Header";
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        with AssemblyHeader do begin
            Copy(Rec);
            AssemblySetup.Get();
            TestNoSeries();
            if NoSeriesMgt.SelectSeries(GetNoSeriesCode(), OldAssemblyHeader."No. Series", "No. Series") then begin
                NoSeriesMgt.SetSeries("No.");
                if AssemblyHeader2.Get("Document Type", "No.") then
                    Error(Text001, Format("Document Type"), "No.");
                Rec := AssemblyHeader;
                exit(true);
            end;
        end;
    end;

    local procedure TestNoSeries()
    begin
        AssemblySetup.Get();
        case "Document Type" of
            "Document Type"::Quote:
                AssemblySetup.TestField("Assembly Quote Nos.");
            "Document Type"::Order:
                begin
                    AssemblySetup.TestField("Posted Assembly Order Nos.");
                    AssemblySetup.TestField("Assembly Order Nos.");
                end;
            "Document Type"::"Blanket Order":
                AssemblySetup.TestField("Blanket Assembly Order Nos.");
        end;
    end;

    local procedure GetNoSeriesCode() Result: Code[20]
    begin
        case "Document Type" of
            "Document Type"::Quote:
                Result := AssemblySetup."Assembly Quote Nos.";
            "Document Type"::Order:
                Result := AssemblySetup."Assembly Order Nos.";
            "Document Type"::"Blanket Order":
                Result := AssemblySetup."Blanket Assembly Order Nos.";
        end;
        OnAfterGetNoSeriesCode(Rec, Result);
    end;

    local procedure GetPostingNoSeriesCode(): Code[20]
    begin
        exit(AssemblySetup."Posted Assembly Order Nos.");
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure DeleteAssemblyLines()
    var
        AssemblyLine: Record "Assembly Line";
        ReservMgt: Codeunit "Reservation Management";
    begin
        AssemblyLine.SetRange("Document Type", "Document Type");
        AssemblyLine.SetRange("Document No.", "No.");
        if AssemblyLine.Find('-') then begin
            ReservMgt.DeleteDocumentReservation(
                DATABASE::"Assembly Line", "Document Type".AsInteger(), "No.", HideValidationDialog);
            repeat
                AssemblyLine.SuspendStatusCheck(true);
                AssemblyLine.Delete(true);
            until AssemblyLine.Next() = 0;
        end;
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

        TestField("Item No.");
        Clear(Reservation);
        Reservation.SetReservSource(Rec);
        Reservation.RunModal();
    end;

    procedure ShowReservationEntries(Modal: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        TestField("Item No.");
        ReservEntry.InitSortingAndFilters(true);
        SetReservationFilters(ReservEntry);
        if Modal then
            PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry)
        else
            PAGE.Run(PAGE::"Reservation Entries", ReservEntry);
    end;

    procedure AutoReserveAsmLine(AssemblyLine: Record "Assembly Line")
    begin
        if AssemblyLine.Reserve = AssemblyLine.Reserve::Always then
            AssemblyLine.AutoReserve();
    end;

    procedure SetTestReservationDateConflict(NewTestReservationDateConflict: Boolean)
    begin
        TestReservationDateConflict := NewTestReservationDateConflict;
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
        DimMgt: Codeunit DimensionManagement;
    begin
        SourceCodeSetup.Get();

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup.Assembly,
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
        if "No." <> '' then
            DimMgt.UpdateGlobalDimFromDimSetID(
              "Dimension Set ID",
              "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterCreateDim(Rec, DefaultDimSource);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
        OldDimSetID: Integer;
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        if OldDimSetID <> "Dimension Set ID" then begin
            Modify();
            if AssemblyOrderLineExist() then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure AssemblyOrderLineExist(): Boolean
    var
        AssemblyOrderLine: Record "Assembly Line";
    begin
        AssemblyOrderLine.SetRange("Document Type", "Document Type");
        AssemblyOrderLine.SetRange("Document No.", "No.");
        exit(not AssemblyOrderLine.IsEmpty());
    end;

    local procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        AssemblyOrderLine: Record "Assembly Line";
        DimMgt: Codeunit DimensionManagement;
        NewDimSetID: Integer;
        OldDimSetID: Integer;
        IsHandled: Boolean;
    begin
        // Update all lines with changed dimensions.
        if NewParentDimSetID = OldParentDimSetID then
            exit;

        IsHandled := false;
        OnUpdateAllLineDimOnBeforeConfirmUpdatedDimension(Rec, IsHandled);
        if not IsHandled and GuiAllowed then
            if not Confirm(UpdatedimensionLineMsg) then
                exit;

        AssemblyOrderLine.SetRange("Document Type", "Document Type");
        AssemblyOrderLine.SetRange("Document No.", "No.");
        AssemblyOrderLine.LockTable();
        if AssemblyOrderLine.Find('-') then
            repeat
                OldDimSetID := AssemblyOrderLine."Dimension Set ID";
                NewDimSetID := DimMgt.GetDeltaDimSetID(AssemblyOrderLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if AssemblyOrderLine."Dimension Set ID" <> NewDimSetID then begin
                    AssemblyOrderLine."Dimension Set ID" := NewDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      AssemblyOrderLine."Dimension Set ID", AssemblyOrderLine."Shortcut Dimension 1 Code", AssemblyOrderLine."Shortcut Dimension 2 Code");
                    AssemblyOrderLine.Modify();
                end;
            until AssemblyOrderLine.Next() = 0;
    end;

    local procedure GetItem()
    begin
        TestField("Item No.");
        if Item."No." <> "Item No." then
            Item.Get("Item No.");
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    local procedure GetLocation(var Location: Record Location; LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    procedure GetRemainingQty(var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        RemainingQty := "Remaining Quantity" - Abs("Reserved Quantity");
        RemainingQtyBase := "Remaining Quantity (Base)" - Abs("Reserved Qty. (Base)");
    end;

    procedure GetReservationQty(var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal): Decimal
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        QtyReserved := "Reserved Quantity";
        QtyReservedBase := "Reserved Qty. (Base)";
        QtyToReserve := "Remaining Quantity";
        QtyToReserveBase := "Remaining Quantity (Base)";
        exit("Qty. per Unit of Measure");
    end;

    procedure GetSourceCaption(): Text[80]
    begin
        exit(StrSubstNo('%1 %2', "Document Type", "No."));
    end;

    procedure SetReservationEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSource(DATABASE::"Assembly Header", "Document Type".AsInteger(), "No.", 0, '', 0);
        ReservEntry.SetItemData("Item No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        ReservEntry."Expected Receipt Date" := "Due Date";
        ReservEntry."Shipment Date" := "Due Date";
    end;

    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter(DATABASE::"Assembly Header", "Document Type".AsInteger(), "No.", 0, false);
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

    procedure SetItemToPlanFilters(var Item: Record Item; DocumentType: Enum "Assembly Document Type")
    begin
        Reset();
        SetCurrentKey("Document Type", "Item No.", "Variant Code", "Location Code");
        SetRange("Document Type", DocumentType);
        SetRange("Item No.", Item."No.");
        SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        SetFilter("Location Code", Item.GetFilter("Location Filter"));
        SetFilter("Due Date", Item.GetFilter("Date Filter"));
        SetFilter("Shortcut Dimension 1 Code", Item.GetFilter("Global Dimension 1 Filter"));
        SetFilter("Shortcut Dimension 2 Code", Item.GetFilter("Global Dimension 2 Filter"));
        SetFilter("Remaining Quantity (Base)", '<>0');
        SetFilter("Unit of Measure Code", Item.GetFilter("Unit of Measure Filter"));

        OnAfterSetItemToPlanFilters(Rec, Item, DocumentType);
    end;

    procedure FindItemToPlanLines(var Item: Record Item; DocumentType: Enum "Assembly Document Type"): Boolean
    begin
        SetItemToPlanFilters(Item, DocumentType);
        exit(Find('-'));
    end;

    procedure ItemToPlanLinesExist(var Item: Record Item; DocumentType: Enum "Assembly Document Type"): Boolean
    begin
        SetItemToPlanFilters(Item, DocumentType);
        exit(not IsEmpty);
    end;

    procedure FilterLinesForReservation(ReservationEntry: Record "Reservation Entry"; DocumentType: Option; AvailabilityFilter: Text; Positive: Boolean)
    begin
        Reset();
        SetCurrentKey(
          "Document Type", "Item No.", "Variant Code", "Location Code", "Due Date");
        SetRange("Document Type", DocumentType);
        SetRange("Item No.", ReservationEntry."Item No.");
        SetRange("Variant Code", ReservationEntry."Variant Code");
        SetRange("Location Code", ReservationEntry."Location Code");
        SetFilter("Due Date", AvailabilityFilter);
        if Positive then
            SetFilter("Remaining Quantity (Base)", '>0')
        else
            SetFilter("Remaining Quantity (Base)", '<0');

        OnAfterFilterLinesForReservation(Rec, ReservationEntry, DocumentType, AvailabilityFilter, Positive);
    end;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
        OldDimSetId: Integer;
    begin
        OldDimSetId := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2', "Document Type", "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if OldDimSetId <> "Dimension Set ID" then begin
            SetCurrentFieldNum(FieldNo("Dimension Set ID"));
            AssemblyLineMgt.UpdateAssemblyLines(Rec, xRec, FieldNo("Dimension Set ID"), false, CurrFieldNo, CurrentFieldNum);
            ClearCurrentFieldNum(FieldNo("Dimension Set ID"));
            Modify(true);
        end;
        OnAfterShowDimensions(Rec);
    end;

    procedure ShowStatistics()
    begin
        TestField("Item No.");
        PAGE.Run(PAGE::"Assembly Order Statistics", Rec);
    end;

    procedure UpdateUnitCost()
    var
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        RolledUpAsmUnitCost: Decimal;
        OverHeadAmt: Decimal;
    begin
        RolledUpAsmUnitCost := CalcRolledUpAsmUnitCost();
        OverHeadAmt := CalculateStandardCost.CalcOverHeadAmt(RolledUpAsmUnitCost, "Indirect Cost %", "Overhead Rate");
        Validate("Unit Cost", RoundUnitAmount(RolledUpAsmUnitCost + OverHeadAmt));
        Modify(true);
    end;

    local procedure CalcRolledUpAsmUnitCost(): Decimal
    begin
        TestField(Quantity);
        CalcFields("Rolled-up Assembly Cost");

        exit("Rolled-up Assembly Cost" / Quantity);
    end;

    local procedure SetDefaultLocation()
    var
        AsmSetup: Record "Assembly Setup";
    begin
        if AsmSetup.Get() then
            if AsmSetup."Default Location for Orders" <> '' then
                if "Location Code" = '' then
                    Validate("Location Code", AsmSetup."Default Location for Orders");
    end;

    procedure SetItemFilter(var Item: Record Item)
    begin
        if "Due Date" = 0D then
            "Due Date" := WorkDate();
        Item.SetRange("Date Filter", 0D, "Due Date");
        Item.SetRange("Location Filter", "Location Code");
        Item.SetRange("Variant Filter", "Variant Code");
    end;

    procedure ShowAssemblyList()
    var
        BOMComponent: Record "BOM Component";
    begin
        TestField("Item No.");
        BOMComponent.SetRange("Parent Item No.", "Item No.");
        PAGE.Run(PAGE::"Assembly BOM", BOMComponent);
    end;

    local procedure CalcBaseQty(Qty: Decimal; FromFieldName: Text; ToFieldName: Text) Result: Decimal
    var
        UOMMgt: Codeunit "Unit of Measure Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcBaseQty(Rec, Qty, FromFieldName, ToFieldName, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(UOMMgt.CalcBaseQty(
            "Item No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName));
    end;

    procedure RoundQty(var Qty: Decimal)
    var
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        Qty := UOMMgt.RoundQty(Qty, "Qty. Rounding Precision");
        OnAfterRoundQty(Rec, Qty);
    end;

    local procedure GetSKU()
    var
        SKU: Record "Stockkeeping Unit";
        Result: Boolean;
    begin
        if (StockkeepingUnit."Location Code" = "Location Code") and
           (StockkeepingUnit."Item No." = "Item No.") and
           (StockkeepingUnit."Variant Code" = "Variant Code")
        then
            exit;

        GetItem();
        StockkeepingUnit := Item.GetSKU("Location Code", "Variant Code");
        Result := SKU.Get("Location Code", "Item No.", "Variant Code");

        OnAfterGetSKU(Rec, Result);
    end;

    local procedure GetUnitCost(): Decimal
    var
        SkuItemUnitCost: Decimal;
    begin
        if "Item No." = '' then
            exit(0);

        GetItem();
        GetSKU();
        SkuItemUnitCost := StockkeepingUnit."Unit Cost" * "Qty. per Unit of Measure";

        exit(RoundUnitAmount(SkuItemUnitCost));
    end;

    local procedure RoundUnitAmount(UnitAmount: Decimal): Decimal
    begin
        GetGLSetup();

        exit(Round(UnitAmount, GLSetup."Unit-Amount Rounding Precision"));
    end;

    procedure CalcActualCosts(var ActCost: array[5] of Decimal)
    var
        TempSourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)" temporary;
        CalcInvtAdjmtOrder: Codeunit "Calc. Inventory Adjmt. - Order";
    begin
        TempSourceInvtAdjmtEntryOrder.SetAsmOrder(Rec);
        CalcInvtAdjmtOrder.CalcActualUsageCosts(TempSourceInvtAdjmtEntryOrder, "Assembled Quantity (Base)", TempSourceInvtAdjmtEntryOrder);
        ActCost[RowIdx::MatCost] := TempSourceInvtAdjmtEntryOrder."Single-Level Material Cost";
        ActCost[RowIdx::ResCost] := TempSourceInvtAdjmtEntryOrder."Single-Level Capacity Cost";
        ActCost[RowIdx::ResOvhd] := TempSourceInvtAdjmtEntryOrder."Single-Level Cap. Ovhd Cost";
        ActCost[RowIdx::AsmOvhd] := TempSourceInvtAdjmtEntryOrder."Single-Level Mfg. Ovhd Cost";
    end;

    procedure CalcStartDateFromEndDate(EndingDate: Date) Result: Date
    var
        ReqLine: Record "Requisition Line";
        LeadTimeMgt: Codeunit "Lead-Time Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcStartDateFromEndDate(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Result :=
          LeadTimeMgt.PlannedStartingDate(
            "Item No.", "Location Code", "Variant Code", '',
            LeadTimeMgt.ManufacturingLeadTime("Item No.", "Location Code", "Variant Code"),
            ReqLine."Ref. Order Type"::Assembly, EndingDate);

        OnAfterCalcStartDateFromEndDate(Rec, Result);
    end;

    procedure CalcEndDateFromStartDate(StartingDate: Date) Result: Date
    var
        ReqLine: Record "Requisition Line";
        LeadTimeMgt: Codeunit "Lead-Time Management";
    begin
        OnBeforeCalcEndDateFromStartDate(Rec);

        Result :=
          LeadTimeMgt.PlannedEndingDate(
            "Item No.", "Location Code", "Variant Code", '',
            LeadTimeMgt.ManufacturingLeadTime("Item No.", "Location Code", "Variant Code"),
            ReqLine."Ref. Order Type"::Assembly, StartingDate);

        OnAfterCalcEndDateFromStartDate(Rec, Result);
    end;

    procedure CalcEndDateFromDueDate(DueDate: Date): Date
    var
        ReqLine: Record "Requisition Line";
        LeadTimeMgt: Codeunit "Lead-Time Management";
    begin
        exit(
          LeadTimeMgt.PlannedEndingDate(
            "Item No.", "Location Code", "Variant Code", DueDate, '', ReqLine."Ref. Order Type"::Assembly));
    end;

    procedure CalcDueDateFromEndDate(EndingDate: Date): Date
    var
        ReqLine: Record "Requisition Line";
        LeadTimeMgt: Codeunit "Lead-Time Management";
    begin
        exit(
          LeadTimeMgt.PlannedDueDate(
            "Item No.", "Location Code", "Variant Code", EndingDate, '', ReqLine."Ref. Order Type"::Assembly));
    end;

    local procedure UpdateAssemblyLinesAndVerifyReserveQuantity()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAssemblyLinesAndVerifyReserveQuantity(Rec, xRec, CurrFieldNo, CurrentFieldNum, IsHandled);
        if IsHandled then
            exit;

        AssemblyLineMgt.UpdateAssemblyLines(Rec, xRec, FieldNo(Quantity), ReplaceLinesFromBOM(), CurrFieldNo, CurrentFieldNum);
        AssemblyHeaderReserve.VerifyQuantity(Rec, xRec);
    end;

    procedure ValidateDates(FieldNumToCalculateFrom: Integer; DoNotValidateButJustAssign: Boolean)
    var
        NewDueDate: Date;
        NewEndDate: Date;
        NewStartDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateDates(Rec, FieldNumToCalculateFrom, DoNotValidateButJustAssign, IsHandled);
        if IsHandled then
            exit;

        CalculateNewDates(FieldNumToCalculateFrom, NewDueDate, NewEndDate, NewStartDate);
        if DoNotValidateButJustAssign then
            AssignNewDates(FieldNumToCalculateFrom, NewDueDate, NewEndDate, NewStartDate)
        else
            DoValidateDates(FieldNumToCalculateFrom, NewDueDate, NewEndDate, NewStartDate);

        if "Due Date" < "Ending Date" then
            Error(Text015, FieldCaption("Due Date"), "Due Date", FieldCaption("Ending Date"), "Ending Date");
        if "Ending Date" < "Starting Date" then
            Error(Text015, FieldCaption("Ending Date"), "Ending Date", FieldCaption("Starting Date"), "Starting Date");
    end;

    local procedure CalculateNewDates(FieldNumToCalculateFrom: Integer; var NewDueDate: Date; var NewEndDate: Date; var NewStartDate: Date)
    begin
        case FieldNumToCalculateFrom of
            FieldNo("Due Date"):
                begin
                    NewEndDate := CalcEndDateFromDueDate("Due Date");
                    NewStartDate := CalcStartDateFromEndDate(NewEndDate);
                end;
            FieldNo("Ending Date"):
                begin
                    NewDueDate := CalcDueDateFromEndDate("Ending Date");
                    NewStartDate := CalcStartDateFromEndDate("Ending Date");
                end;
            FieldNo("Starting Date"):
                begin
                    NewEndDate := CalcEndDateFromStartDate("Starting Date");
                    NewDueDate := CalcDueDateFromEndDate(NewEndDate);
                end;
        end;
    end;

    local procedure DoValidateDates(FieldNumToCalculateFrom: Integer; NewDueDate: Date; NewEndDate: Date; NewStartDate: Date)
    var
        ValidateConfirmed: Boolean;
    begin
        ValidateConfirmed := false;
        OnBeforeDoValidateDates(Rec, xRec, FieldNumToCalculateFrom, NewDueDate, NewEndDate, NewStartDate, ValidateConfirmed);

        case FieldNumToCalculateFrom of
            FieldNo("Due Date"):
                begin
                    ValidateEndDate(NewEndDate, false);
                    ValidateStartDate(NewStartDate, false);
                end;
            FieldNo("Ending Date"):
                begin
                    ValidateStartDate(NewStartDate, false);
                    if not IsAsmToOrder() then
                        if "Due Date" <> NewDueDate then begin
                            if not ValidateConfirmed then
                                ValidateConfirmed :=
                                    ConfirmManagement.GetResponse(
                                        StrSubstNo(Text012,
                                            StrSubstNo(Text010,
                                                StrSubstNo(Text011, FieldCaption("Ending Date"), xRec."Ending Date", "Ending Date")),
                                            StrSubstNo(Text013,
                                                StrSubstNo(Text011, FieldCaption("Due Date"), "Due Date", NewDueDate))),
                                        true);
                            if ValidateConfirmed then
                                ValidateDueDate(NewDueDate, false);
                        end;
                end;
            FieldNo("Starting Date"):
                if IsAsmToOrder() then begin
                    if "Ending Date" <> NewEndDate then begin
                        if not ValidateConfirmed then
                            ValidateConfirmed :=
                                ConfirmManagement.GetResponse(
                                    StrSubstNo(Text012,
                                        StrSubstNo(Text010,
                                            StrSubstNo(Text011, FieldCaption("Starting Date"), xRec."Starting Date", "Starting Date")),
                                        StrSubstNo(Text013,
                                            StrSubstNo(Text011, FieldCaption("Ending Date"), "Ending Date", NewEndDate))),
                                    true);
                        if ValidateConfirmed then
                            ValidateEndDate(NewEndDate, false);
                    end;
                end else
                    if ("Ending Date" <> NewEndDate) or ("Due Date" <> NewDueDate) then begin
                        if not ValidateConfirmed then
                            ValidateConfirmed :=
                                ConfirmManagement.GetResponse(
                                    StrSubstNo(Text012,
                                        StrSubstNo(Text010,
                                            StrSubstNo(Text011, FieldCaption("Starting Date"), xRec."Starting Date", "Starting Date")),
                                        StrSubstNo(Text013,
                                            StrSubstNo(Text014,
                                            StrSubstNo(Text011, FieldCaption("Ending Date"), "Ending Date", NewEndDate),
                                            StrSubstNo(Text011, FieldCaption("Due Date"), "Due Date", NewDueDate)))),
                                    true);
                        if ValidateConfirmed then begin
                            ValidateEndDate(NewEndDate, false);
                            ValidateDueDate(NewDueDate, false);
                        end;
                    end
        end;
    end;

    local procedure AssignNewDates(FieldNumToCalculateFrom: Integer; NewDueDate: Date; NewEndDate: Date; NewStartDate: Date)
    begin
        case FieldNumToCalculateFrom of
            FieldNo("Due Date"):
                begin
                    "Ending Date" := NewEndDate;
                    "Starting Date" := NewStartDate;
                end;
            FieldNo("Ending Date"):
                begin
                    "Due Date" := NewDueDate;
                    "Starting Date" := NewStartDate;
                end;
            FieldNo("Starting Date"):
                begin
                    "Ending Date" := NewEndDate;
                    "Due Date" := NewDueDate;
                end;
        end;
    end;

    procedure ValidateDueDate(NewDueDate: Date; CallValidateOnOtherDates: Boolean)
    var
        ReservationCheckDateConfl: Codeunit "Reservation-Check Date Confl.";
    begin
        OnBeforeValidateDueDate(Rec, NewDueDate);
        "Due Date" := NewDueDate;
        CheckIsNotAsmToOrder();
        TestStatusOpen();

        if CallValidateOnOtherDates then
            ValidateDates(FieldNo("Due Date"), false);
        if (xRec."Due Date" <> "Due Date") and (Quantity <> 0) then
            ReservationCheckDateConfl.AssemblyHeaderCheck(Rec, (CurrFieldNo <> 0) or TestReservationDateConflict);
    end;

    procedure ValidateEndDate(NewEndDate: Date; CallValidateOnOtherDates: Boolean)
    begin
        "Ending Date" := NewEndDate;
        TestStatusOpen();

        if CallValidateOnOtherDates then
            ValidateDates(FieldNo("Ending Date"), false);
    end;

    procedure ValidateStartDate(NewStartDate: Date; CallValidateOnOtherDates: Boolean)
    begin
        "Starting Date" := NewStartDate;
        TestStatusOpen();
        SetCurrentFieldNum(FieldNo("Starting Date"));

        AssemblyLineMgt.UpdateAssemblyLines(Rec, xRec, FieldNo("Starting Date"), false, CurrFieldNo, CurrentFieldNum);
        ClearCurrentFieldNum(FieldNo("Starting Date"));
        if CallValidateOnOtherDates then
            ValidateDates(FieldNo("Starting Date"), false);
    end;

    local procedure CheckBin()
    var
        BinContent: Record "Bin Content";
        Bin: Record Bin;
        Location: Record Location;
    begin
        if "Bin Code" <> '' then begin
            GetLocation(Location, "Location Code");
            if not Location."Check Whse. Class" then
                exit;

            if BinContent.Get(
                 "Location Code", "Bin Code",
                 "Item No.", "Variant Code", "Unit of Measure Code")
            then
                BinContent.CheckWhseClass(false)
            else begin
                Bin.Get("Location Code", "Bin Code");
                Bin.CheckWhseClass("Item No.", false);
            end;
        end;
    end;

    procedure GetDefaultBin()
    var
        Location: Record Location;
        WMSManagement: Codeunit "WMS Management";
    begin
        if (Quantity * xRec.Quantity > 0) and
           ("Item No." = xRec."Item No.") and
           ("Location Code" = xRec."Location Code") and
           ("Variant Code" = xRec."Variant Code")
        then
            exit;

        "Bin Code" := '';
        if ("Location Code" <> '') and ("Item No." <> '') then begin
            GetLocation(Location, "Location Code");
            if GetFromAssemblyBin(Location, "Bin Code") then
                exit;

            if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                WMSManagement.GetDefaultBin("Item No.", "Variant Code", "Location Code", "Bin Code");
        end;

        OnAfterGetDefaultBin(Rec);
    end;

    procedure GetFromAssemblyBin(Location: Record Location; var BinCode: Code[20]) BinCodeNotEmpty: Boolean
    begin
        if Location."Bin Mandatory" then
            BinCode := Location."From-Assembly Bin Code";
        BinCodeNotEmpty := BinCode <> '';
    end;

    procedure ValidateBinCode(NewBinCode: Code[20])
    var
        WMSManagement: Codeunit "WMS Management";
        WhseIntegrationMgt: Codeunit "Whse. Integration Management";
    begin
        "Bin Code" := NewBinCode;
        TestStatusOpen();

        if "Bin Code" <> '' then begin
            if Quantity < 0 then
                WMSManagement.FindBinContent("Location Code", "Bin Code", "Item No.", "Variant Code", '')
            else
                WMSManagement.FindBin("Location Code", "Bin Code", '');
            CalcFields("Assemble to Order");
            if not "Assemble to Order" then
                WhseIntegrationMgt.CheckBinTypeCode(DATABASE::"Assembly Header",
                  FieldCaption("Bin Code"),
                  "Location Code",
                  "Bin Code", 0);
            CheckBin();
        end;
    end;

    procedure CreatePick(ShowRequestPage: Boolean; AssignedUserID: Code[50]; SortingMethod: Option; SetBreakBulkFilter: Boolean; DoNotFillQtyToHandle: Boolean; PrintDocument: Boolean)
    begin
        AssemblyLineMgt.CreateWhseItemTrkgForAsmLines(Rec);
        Commit();

        TestField(Status, Status::Released);
        if CompletelyPicked() then
            Error(Text007);

        RunWhseSourceCreateDocument(ShowRequestPage, AssignedUserID, SortingMethod, SetBreakBulkFilter, DoNotFillQtyToHandle, PrintDocument);
    end;

    internal procedure PerformManualRelease()
    begin
        if Rec.Status <> Rec.Status::Released then begin
            CODEUNIT.Run(CODEUNIT::"Release Assembly Document", Rec);
            Commit();
        end;
    end;

    local procedure RunWhseSourceCreateDocument(ShowRequestPage: Boolean; AssignedUserID: Code[50]; SortingMethod: Option; SetBreakBulkFilter: Boolean; DoNotFillQtyToHandle: Boolean; PrintDocument: Boolean)
    var
        WhseSourceCreateDocument: Report "Whse.-Source - Create Document";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunWhseSourceCreateDocument(Rec, ShowRequestPage, AssignedUserID, SortingMethod, SetBreakBulkFilter, DoNotFillQtyToHandle, PrintDocument, IsHandled);
        if not IsHandled then begin
            WhseSourceCreateDocument.SetAssemblyOrder(Rec);
            if not ShowRequestPage then
                WhseSourceCreateDocument.Initialize(
                    AssignedUserID, Enum::"Whse. Activity Sorting Method".FromInteger(SortingMethod), PrintDocument, DoNotFillQtyToHandle, SetBreakBulkFilter);
            WhseSourceCreateDocument.UseRequestPage(ShowRequestPage);
            WhseSourceCreateDocument.RunModal();
            WhseSourceCreateDocument.GetResultMessage(2);
            Clear(WhseSourceCreateDocument);
        end;

        OnAfterRunWhseSourceCreateDocument(Rec, ShowRequestPage, AssignedUserID, SortingMethod, SetBreakBulkFilter, DoNotFillQtyToHandle, PrintDocument);
    end;

    procedure CreateInvtMovement(MakeATOInvtMvmt: Boolean; PrintDocumentForATOMvmt: Boolean; ShowErrorForATOMvmt: Boolean; var ATOMovementsCreated: Integer; var ATOTotalMovementsToBeCreated: Integer)
    var
        WhseRequest: Record "Warehouse Request";
        CreateInvtPutAwayPickMvmt: Report "Create Invt Put-away/Pick/Mvmt";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateInvtMovement(Rec, MakeATOInvtMvmt, PrintDocumentForATOMvmt, ShowErrorForATOMvmt, ATOMovementsCreated, ATOTotalMovementsToBeCreated, IsHandled);
        if IsHandled then
            exit;

        TestField(Status, Status::Released);

        WhseRequest.Reset();
        WhseRequest.SetCurrentKey("Source Document", "Source No.");
        WhseRequest.SetRange("Source Document", WhseRequest."Source Document"::"Assembly Consumption");
        WhseRequest.SetRange("Source No.", "No.");
        CreateInvtPutAwayPickMvmt.SetTableView(WhseRequest);

        if MakeATOInvtMvmt then begin
            CreateInvtPutAwayPickMvmt.InitializeRequest(false, false, true, PrintDocumentForATOMvmt, ShowErrorForATOMvmt);
            CreateInvtPutAwayPickMvmt.SuppressMessages(true);
            CreateInvtPutAwayPickMvmt.UseRequestPage(false);
        end;

        CreateInvtPutAwayPickMvmt.RunModal();
        CreateInvtPutAwayPickMvmt.GetMovementCounters(ATOMovementsCreated, ATOTotalMovementsToBeCreated);
    end;

    procedure CompletelyPicked(): Boolean
    begin
        exit(AssemblyLineMgt.CompletelyPicked(Rec));
    end;

    procedure IsInbound(): Boolean
    begin
        if "Document Type" in ["Document Type"::Order, "Document Type"::Quote, "Document Type"::"Blanket Order"] then
            exit("Quantity (Base)" > 0);

        exit(false);
    end;

    procedure OpenItemTrackingLines()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenItemTrackingLines(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("No.");
        TestField("Quantity (Base)");
        AssemblyHeaderReserve.CallItemTracking(Rec);
    end;

    procedure ItemExists(ItemNo: Code[20]): Boolean
    var
        Item2: Record Item;
    begin
        if not Item2.Get(ItemNo) then
            exit(false);
        exit(true);
    end;

    procedure TestStatusOpen()
    begin
        if StatusCheckSuspended then
            exit;
        TestField(Status, Status::Open);
    end;

    procedure SuspendStatusCheck(Suspend: Boolean)
    begin
        StatusCheckSuspended := Suspend;
    end;

    procedure IsStatusCheckSuspended(): Boolean
    begin
        exit(StatusCheckSuspended);
    end;

    procedure ShowTracking()
    var
        OrderTracking: Page "Order Tracking";
    begin
        OrderTracking.SetAsmHeader(Rec);
        OrderTracking.RunModal();
    end;

    procedure ShowAsmToOrder()
    var
        ATOLink: Record "Assemble-to-Order Link";
    begin
        ATOLink.ShowSales(Rec);
    end;

    procedure IsAsmToOrder(): Boolean
    begin
        CalcFields("Assemble to Order");
        exit("Assemble to Order");
    end;

    procedure CheckIsNotAsmToOrder()
    begin
        CheckIsNotAsmToOrder(0);
    end;

    procedure CheckIsNotAsmToOrder(CallingFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIsNotAsmToOrder(Rec, IsHandled, xRec, CurrFieldNo, CallingFieldNo);
        if IsHandled then
            exit;

        CalcFields("Assemble to Order");
        TestField("Assemble to Order", false);
    end;

    procedure IsStandardCostItem(): Boolean
    begin
        if "Item No." = '' then
            exit(false);
        GetItem();
        exit(Item."Costing Method" = Item."Costing Method"::Standard);
    end;

    [Scope('OnPrem')]
    procedure ShowAvailability()
    var
        TempAssemblyHeader: Record "Assembly Header" temporary;
        TempAssemblyLine: Record "Assembly Line" temporary;
        AsmLineMgt: Codeunit "Assembly Line Management";
    begin
        AsmLineMgt.CopyAssemblyData(Rec, TempAssemblyHeader, TempAssemblyLine);
        AsmLineMgt.ShowAvailability(true, TempAssemblyHeader, TempAssemblyLine);
    end;

    procedure ShowDueDateBeforeWorkDateMsg()
    var
        TempAssemblyHeader: Record "Assembly Header" temporary;
        TempAssemblyLine: Record "Assembly Line" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDueDateBeforeWorkDateMsg(Rec, IsHandled);
        if IsHandled then
            exit;

        AssemblyLineMgt.CopyAssemblyData(Rec, TempAssemblyHeader, TempAssemblyLine);
        if TempAssemblyLine.FindSet() then
            repeat
                if (TempAssemblyLine."Due Date" < WorkDate()) and (TempAssemblyLine."Remaining Quantity" <> 0) then begin
                    AssemblyLineMgt.ShowDueDateBeforeWorkDateMsg(TempAssemblyLine."Due Date");
                    exit;
                end;
            until TempAssemblyLine.Next() = 0;
    end;

    procedure AddBOMLine(BOMComp: Record "BOM Component")
    var
        AsmLine: Record "Assembly Line";
    begin
        AssemblyLineMgt.AddBOMLine(Rec, AsmLine, BOMComp);
        AutoReserveAsmLine(AsmLine);
    end;

    local procedure ReplaceLinesFromBOM(): Boolean
    var
        NoLinesWerePresent: Boolean;
        LinesPresent: Boolean;
        DeleteLines: Boolean;
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        OnBeforeReplaceLinesFromBOM(Rec, xRec, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        NoLinesWerePresent := (xRec.Quantity * xRec."Qty. per Unit of Measure" = 0);
        LinesPresent := (Quantity * "Qty. per Unit of Measure" <> 0);
        DeleteLines := (Quantity = 0);

        exit((NoLinesWerePresent and LinesPresent) or DeleteLines);
    end;

    local procedure SetCurrentFieldNum(NewCurrentFieldNum: Integer): Boolean
    begin
        if CurrentFieldNum = 0 then begin
            CurrentFieldNum := NewCurrentFieldNum;
            exit(true);
        end;
        exit(false);
    end;

    local procedure ClearCurrentFieldNum(NewCurrentFieldNum: Integer)
    begin
        if CurrentFieldNum = NewCurrentFieldNum then
            CurrentFieldNum := 0;
    end;

    procedure UpdateWarningOnLines()
    begin
        AssemblyLineMgt.UpdateWarningOnLines(Rec);
    end;

    procedure SetWarningsOff()
    begin
        AssemblyLineMgt.SetWarningsOff();
    end;

    procedure SetWarningsOn()
    begin
        AssemblyLineMgt.SetWarningsOn();
    end;

    local procedure SetDescriptionsFromItem()
    begin
        GetItem();
        Description := Item.Description;
        "Description 2" := Item."Description 2";
    end;

    procedure CalcTotalCost(var ExpCost: array[5] of Decimal): Decimal
    var
        Resource: Record Resource;
        AssemblyLine: Record "Assembly Line";
        DirectLineCost: Decimal;
    begin
        GLSetup.Get();

        AssemblyLine.SetRange("Document Type", "Document Type");
        AssemblyLine.SetRange("Document No.", "No.");
        if AssemblyLine.FindSet() then
            repeat
                case AssemblyLine.Type of
                    AssemblyLine.Type::Item:
                        ExpCost[RowIdx::MatCost] += AssemblyLine."Cost Amount";
                    AssemblyLine.Type::Resource:
                        begin
                            Resource.Get(AssemblyLine."No.");
                            DirectLineCost :=
                              Round(
                                Resource."Direct Unit Cost" * AssemblyLine."Quantity (Base)",
                                GLSetup."Unit-Amount Rounding Precision");
                            ExpCost[RowIdx::ResCost] += DirectLineCost;
                            ExpCost[RowIdx::ResOvhd] += AssemblyLine."Cost Amount" - DirectLineCost;
                        end;
                end
            until AssemblyLine.Next() = 0;

        exit(ExpCost[RowIdx::MatCost] + ExpCost[RowIdx::ResCost] + ExpCost[RowIdx::ResOvhd]);
    end;

    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(ItemTrackingMgt.ComposeRowID(DATABASE::"Assembly Header", "Document Type".AsInteger(), "No.", '', 0, 0));
    end;

    procedure CreateDimFromDefaultDim()
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::Item, Rec."Item No.");
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."Location Code");

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, CurrFieldNo);
    end;

    internal procedure GetQtyReservedFromStockState() Result: Enum "Reservation From Stock"
    var
        AssemblyLineLocal: Record "Assembly Line";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        QtyReservedFromStock: Decimal;
    begin
        QtyReservedFromStock := AssemblyLineReserve.GetReservedQtyFromInventory(Rec);

        AssemblyLineLocal.SetRange("Document Type", "Document Type");
        AssemblyLineLocal.SetRange("Document No.", "No.");
        AssemblyLineLocal.SetRange(Type, AssemblyLineLocal.Type::Item);
        AssemblyLineLocal.CalcSums("Remaining Quantity (Base)");

        case QtyReservedFromStock of
            0:
                exit(Result::None);
            AssemblyLineLocal."Remaining Quantity (Base)":
                exit(Result::Full);
            else
                exit(Result::Partial);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var AssemblyHeader: Record "Assembly Header"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcEndDateFromStartDate(var AssemblyHeader: Record "Assembly Header"; var Result: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcStartDateFromEndDate(var AssemblyHeader: Record "Assembly Header"; var Result: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetNoSeriesCode(AssemblyHeader: Record "Assembly Header"; var Result: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSKU(AssemblyHeader: Record "Assembly Header"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var AssemblyHeader: Record "Assembly Header"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesForReservation(var AssemblyHeader: Record "Assembly Header"; ReservEntry: Record "Reservation Entry"; DocumentType: Option; AvailabilityFilter: Text; Positive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToAssemble(var AssemblyHeader: Record "Assembly Header"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRecord(var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRemaining(var AssemblyHeader: Record "Assembly Header"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRoundQty(AssemblyHeader: Record "Assembly Header"; var Qty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetItemToPlanFilters(var AssemblyHeader: Record "Assembly Header"; var Item: Record Item; AssemblyDocumentType: Enum "Assembly Document Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; AssemblyHeader: Record "Assembly Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var AssemblyHeader: Record "Assembly Header"; var xAssemblyHeader: Record "Assembly Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoValidateDates(var AssemblyHeader: Record "Assembly Header"; var xAssemblyHeader: Record "Assembly Header"; FieldNumToCalculateFrom: Integer; NewDueDate: Date; NewEndDate: Date; NewStartDate: Date; var ValidateConfirmed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenItemTrackingLines(var AssemblyHeader: Record "Assembly Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDueDateBeforeWorkDateMsg(AssemblyHeader: Record "Assembly Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDueDate(var AssemblyHeader: Record "Assembly Header"; NewDueDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReplaceLinesFromBOM(var AssemblyHeader: Record "Assembly Header"; xAssemblyHeader: Record "Assembly Header"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunWhseSourceCreateDocument(var AssemblyHeader: Record "Assembly Header"; ShowRequestPage: Boolean; AssignedUserID: Code[50]; SortingMethod: Option; SetBreakBulkFilter: Boolean; DoNotFillQtyToHandle: Boolean; PrintDocument: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateInvtMovement(var AssemblyHeader: Record "Assembly Header"; MakeATOInvtMvmt: Boolean; PrintDocumentForATOMvmt: Boolean; ShowErrorForATOMvmt: Boolean; var ATOMovementsCreated: Integer; var ATOTotalMovementsToBeCreated: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterGetDefaultBin(var AssemblyHeader: Record "Assembly Header"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnBeforeValidateDates(var AssemblyHeader: Record "Assembly Header"; xAssemblyHeader: Record "Assembly Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLocationCodeOnBeforeValidateDates(var AssemblyHeader: Record "Assembly Header"; xAssemblyHeader: Record "Assembly Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValiateQuantityOnAfterCalcBaseQty(var AssemblyHeader: Record "Assembly Header"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var AssemblyHeader: Record "Assembly Header"; var xAssemblyHeader: Record "Assembly Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityBase(var AssemblyHeader: Record "Assembly Header"; var xAssemblyHeader: Record "Assembly Header"; FieldNumber: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantity(var AssemblyHeader: Record "Assembly Header"; var xAssemblyHeader: Record "Assembly Header"; FieldNumber: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVariantCodeOnBeforeUpdateAssemblyLines(var AssemblyHeader: Record "Assembly Header"; xAssemblyHeader: Record "Assembly Header"; CurrentFieldNo: Integer; CurrentFieldNum: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVariantCodeOnBeforeValidateDates(var AssemblyHeader: Record "Assembly Header"; xAssemblyHeader: Record "Assembly Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAssemblyLinesAndVerifyReserveQuantity(var AssemblyHeader: Record "Assembly Header"; var xAssemblyHeader: Record "Assembly Header"; CallingFieldNo: Integer; CurrentFieldNum: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcBaseQty(var AssemblyHeader: Record "Assembly Header"; Qty: Decimal; FromFieldName: Text; ToFieldName: Text; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcStartDateFromEndDate(var AssemblyHeader: Record "Assembly Header"; var Result: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcEndDateFromStartDate(var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIsNotAsmToOrder(var AssemblyHeader: Record "Assembly Header"; var IsHandled: Boolean; xAssemblyHeader: Record "Assembly Header"; CurrentFieldNo: Integer; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowReservation(var AssemblyHeader: Record "Assembly Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDates(var AssemblyHeader: Record "Assembly Header"; FieldNumToCalculateFrom: Integer; var DoNotValidateButJustAssign: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnBeforeConfirmUpdatedDimension(var AssemblyHeader: Record "Assembly Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDefaultBin(var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRunWhseSourceCreateDocument(var AssemblyHeader: Record "Assembly Header"; ShowRequestPage: Boolean; AssignedUserID: Code[50]; SortingMethod: Option; SetBreakBulkFilter: Boolean; DoNotFillQtyToHandle: Boolean; PrintDocument: Boolean)
    begin
    end;
}

