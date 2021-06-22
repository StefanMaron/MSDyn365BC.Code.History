table 5740 "Transfer Header"
{
    Caption = 'Transfer Header';
    DataCaptionFields = "No.";
    LookupPageID = "Transfer Orders";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    GetInventorySetup;
                    NoSeriesMgt.TestManual(GetNoSeriesCode);
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Transfer-from Code"; Code[10])
        {
            Caption = 'Transfer-from Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));

            trigger OnValidate()
            var
                Location: Record Location;
                Confirmed: Boolean;
                IsHandled: Boolean;
            begin
                TestStatusOpen;

                IsHandled := false;
                OnBeforeValidateTransferFromCode(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if ("Transfer-from Code" = "Transfer-to Code") and ("Transfer-from Code" <> '') then
                    Error(
                      Text001,
                      FieldCaption("Transfer-from Code"), FieldCaption("Transfer-to Code"),
                      TableCaption, "No.");

                if "Direct Transfer" then
                    VerifyNoOutboundWhseHandlingOnLocation("Transfer-from Code");

                if xRec."Transfer-from Code" <> "Transfer-from Code" then begin
                    if HideValidationDialog or
                       (xRec."Transfer-from Code" = '')
                    then
                        Confirmed := true
                    else
                        Confirmed := Confirm(Text002, false, FieldCaption("Transfer-from Code"));
                    if Confirmed then begin
                        if Location.Get("Transfer-from Code") then begin
                            "Transfer-from Name" := Location.Name;
                            "Transfer-from Name 2" := Location."Name 2";
                            "Transfer-from Address" := Location.Address;
                            "Transfer-from Address 2" := Location."Address 2";
                            "Transfer-from Post Code" := Location."Post Code";
                            "Transfer-from City" := Location.City;
                            "Transfer-from County" := Location.County;
                            "Trsf.-from Country/Region Code" := Location."Country/Region Code";
                            "Transfer-from Contact" := Location.Contact;
                            if not "Direct Transfer" then begin
                                "Outbound Whse. Handling Time" := Location."Outbound Whse. Handling Time";
                                TransferRoute.GetTransferRoute(
                                  "Transfer-from Code", "Transfer-to Code", "In-Transit Code",
                                  "Shipping Agent Code", "Shipping Agent Service Code");
                                OnAfterGetTransferRoute(Rec, TransferRoute);
                                TransferRoute.GetShippingTime(
                                  "Transfer-from Code", "Transfer-to Code",
                                  "Shipping Agent Code", "Shipping Agent Service Code",
                                  "Shipping Time");
                                TransferRoute.CalcReceiptDate(
                                  "Shipment Date",
                                  "Receipt Date",
                                  "Shipping Time",
                                  "Outbound Whse. Handling Time",
                                  "Inbound Whse. Handling Time",
                                  "Transfer-from Code",
                                  "Transfer-to Code",
                                  "Shipping Agent Code",
                                  "Shipping Agent Service Code");
                            end;
                            TransLine.LockTable();
                            TransLine.SetRange("Document No.", "No.");
                        end;
                        UpdateTransLines(Rec, FieldNo("Transfer-from Code"));
                    end else
                        "Transfer-from Code" := xRec."Transfer-from Code";
                end;
            end;
        }
        field(3; "Transfer-from Name"; Text[100])
        {
            Caption = 'Transfer-from Name';
        }
        field(4; "Transfer-from Name 2"; Text[50])
        {
            Caption = 'Transfer-from Name 2';
        }
        field(5; "Transfer-from Address"; Text[100])
        {
            Caption = 'Transfer-from Address';
        }
        field(6; "Transfer-from Address 2"; Text[50])
        {
            Caption = 'Transfer-from Address 2';
        }
        field(7; "Transfer-from Post Code"; Code[20])
        {
            Caption = 'Transfer-from Post Code';
            TableRelation = IF ("Trsf.-from Country/Region Code" = CONST('')) "Post Code"
            ELSE
            IF ("Trsf.-from Country/Region Code" = FILTER(<> '')) "Post Code" WHERE("Country/Region Code" = FIELD("Trsf.-from Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(
                  "Transfer-from City", "Transfer-from Post Code", "Transfer-from County", "Trsf.-from Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(
                  "Transfer-from City", "Transfer-from Post Code",
                  "Transfer-from County", "Trsf.-from Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(8; "Transfer-from City"; Text[30])
        {
            Caption = 'Transfer-from City';
            TableRelation = IF ("Trsf.-from Country/Region Code" = CONST('')) "Post Code".City
            ELSE
            IF ("Trsf.-from Country/Region Code" = FILTER(<> '')) "Post Code".City WHERE("Country/Region Code" = FIELD("Trsf.-from Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(
                  "Transfer-from City", "Transfer-from Post Code", "Transfer-from County", "Trsf.-from Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(
                  "Transfer-from City", "Transfer-from Post Code",
                  "Transfer-from County", "Trsf.-from Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(9; "Transfer-from County"; Text[30])
        {
            CaptionClass = '5,1,' + "Trsf.-from Country/Region Code";
            Caption = 'Transfer-from County';
        }
        field(10; "Trsf.-from Country/Region Code"; Code[10])
        {
            Caption = 'Trsf.-from Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(
                  "Transfer-from City", "Transfer-from Post Code", "Transfer-from County",
                  "Trsf.-from Country/Region Code", xRec."Trsf.-from Country/Region Code");
            end;
        }
        field(11; "Transfer-to Code"; Code[10])
        {
            Caption = 'Transfer-to Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));

            trigger OnValidate()
            var
                Location: Record Location;
                Confirmed: Boolean;
            begin
                TestStatusOpen;

                if ("Transfer-from Code" = "Transfer-to Code") and
                   ("Transfer-to Code" <> '')
                then
                    Error(
                      Text001,
                      FieldCaption("Transfer-from Code"), FieldCaption("Transfer-to Code"),
                      TableCaption, "No.");

                if "Direct Transfer" then
                    VerifyNoInboundWhseHandlingOnLocation("Transfer-to Code");

                if xRec."Transfer-to Code" <> "Transfer-to Code" then begin
                    if HideValidationDialog or (xRec."Transfer-to Code" = '') then
                        Confirmed := true
                    else
                        Confirmed := Confirm(Text002, false, FieldCaption("Transfer-to Code"));
                    if Confirmed then begin
                        if Location.Get("Transfer-to Code") then begin
                            "Transfer-to Name" := Location.Name;
                            "Transfer-to Name 2" := Location."Name 2";
                            "Transfer-to Address" := Location.Address;
                            "Transfer-to Address 2" := Location."Address 2";
                            "Transfer-to Post Code" := Location."Post Code";
                            "Transfer-to City" := Location.City;
                            "Transfer-to County" := Location.County;
                            "Trsf.-to Country/Region Code" := Location."Country/Region Code";
                            "Transfer-to Contact" := Location.Contact;
                            if not "Direct Transfer" then begin
                                "Inbound Whse. Handling Time" := Location."Inbound Whse. Handling Time";
                                TransferRoute.GetTransferRoute(
                                  "Transfer-from Code", "Transfer-to Code", "In-Transit Code",
                                  "Shipping Agent Code", "Shipping Agent Service Code");
                                OnAfterGetTransferRoute(Rec, TransferRoute);
                                TransferRoute.GetShippingTime(
                                  "Transfer-from Code", "Transfer-to Code",
                                  "Shipping Agent Code", "Shipping Agent Service Code",
                                  "Shipping Time");
                                TransferRoute.CalcReceiptDate(
                                  "Shipment Date",
                                  "Receipt Date",
                                  "Shipping Time",
                                  "Outbound Whse. Handling Time",
                                  "Inbound Whse. Handling Time",
                                  "Transfer-from Code",
                                  "Transfer-to Code",
                                  "Shipping Agent Code",
                                  "Shipping Agent Service Code");
                            end;
                            TransLine.LockTable();
                            TransLine.SetRange("Document No.", "No.");
                        end;
                        UpdateTransLines(Rec, FieldNo("Transfer-to Code"));
                    end else
                        "Transfer-to Code" := xRec."Transfer-to Code";
                end;
            end;
        }
        field(12; "Transfer-to Name"; Text[100])
        {
            Caption = 'Transfer-to Name';
        }
        field(13; "Transfer-to Name 2"; Text[50])
        {
            Caption = 'Transfer-to Name 2';
        }
        field(14; "Transfer-to Address"; Text[100])
        {
            Caption = 'Transfer-to Address';
        }
        field(15; "Transfer-to Address 2"; Text[50])
        {
            Caption = 'Transfer-to Address 2';
        }
        field(16; "Transfer-to Post Code"; Code[20])
        {
            Caption = 'Transfer-to Post Code';
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(
                  "Transfer-to City", "Transfer-to Post Code", "Transfer-to County", "Trsf.-to Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(
                  "Transfer-to City", "Transfer-to Post Code", "Transfer-to County",
                  "Trsf.-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(17; "Transfer-to City"; Text[30])
        {
            Caption = 'Transfer-to City';
            TableRelation = IF ("Trsf.-to Country/Region Code" = CONST('')) "Post Code".City
            ELSE
            IF ("Trsf.-to Country/Region Code" = FILTER(<> '')) "Post Code".City WHERE("Country/Region Code" = FIELD("Trsf.-to Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(
                  "Transfer-to City", "Transfer-to Post Code", "Transfer-to County", "Trsf.-to Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(
                  "Transfer-to City", "Transfer-to Post Code", "Transfer-to County",
                  "Trsf.-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(18; "Transfer-to County"; Text[30])
        {
            CaptionClass = '5,1,' + "Trsf.-to Country/Region Code";
            Caption = 'Transfer-to County';
        }
        field(19; "Trsf.-to Country/Region Code"; Code[10])
        {
            Caption = 'Trsf.-to Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(
                  "Transfer-to City", "Transfer-to Post Code", "Transfer-to County",
                  "Trsf.-to Country/Region Code", xRec."Trsf.-to Country/Region Code");
            end;
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(21; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';

            trigger OnValidate()
            begin
                TestStatusOpen;
                TransferRoute.CalcReceiptDate(
                  "Shipment Date",
                  "Receipt Date",
                  "Shipping Time",
                  "Outbound Whse. Handling Time",
                  "Inbound Whse. Handling Time",
                  "Transfer-from Code",
                  "Transfer-to Code",
                  "Shipping Agent Code",
                  "Shipping Agent Service Code");
                UpdateTransLines(Rec, FieldNo("Shipment Date"));
            end;
        }
        field(22; "Receipt Date"; Date)
        {
            Caption = 'Receipt Date';

            trigger OnValidate()
            begin
                TestStatusOpen;
                TransferRoute.CalcShipmentDate(
                  "Shipment Date",
                  "Receipt Date",
                  "Shipping Time",
                  "Outbound Whse. Handling Time",
                  "Inbound Whse. Handling Time",
                  "Transfer-from Code",
                  "Transfer-to Code",
                  "Shipping Agent Code",
                  "Shipping Agent Service Code");
                UpdateTransLines(Rec, FieldNo("Receipt Date"));
            end;
        }
        field(23; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;

            trigger OnValidate()
            begin
                UpdateTransLines(Rec, FieldNo(Status));
            end;
        }
        field(24; Comment; Boolean)
        {
            CalcFormula = Exist ("Inventory Comment Line" WHERE("Document Type" = CONST("Transfer Order"),
                                                                "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(25; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(26; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(27; "In-Transit Code"; Code[10])
        {
            Caption = 'In-Transit Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(true));

            trigger OnValidate()
            begin
                TestStatusOpen;
                UpdateTransLines(Rec, FieldNo("In-Transit Code"));
            end;
        }
        field(28; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(29; "Last Shipment No."; Code[20])
        {
            Caption = 'Last Shipment No.';
            Editable = false;
            TableRelation = "Transfer Shipment Header";
        }
        field(30; "Last Receipt No."; Code[20])
        {
            Caption = 'Last Receipt No.';
            Editable = false;
            TableRelation = "Transfer Receipt Header";
        }
        field(31; "Transfer-from Contact"; Text[100])
        {
            Caption = 'Transfer-from Contact';
        }
        field(32; "Transfer-to Contact"; Text[100])
        {
            Caption = 'Transfer-to Contact';
        }
        field(33; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';

            trigger OnValidate()
            var
                WhseTransferRelease: Codeunit "Whse.-Transfer Release";
            begin
                if (xRec."External Document No." <> "External Document No.") and (Status = Status::Released) then
                    WhseTransferRelease.UpdateExternalDocNoForReleasedOrder(Rec);
            end;
        }
        field(34; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";

            trigger OnValidate()
            begin
                TestStatusOpen;
                if "Shipping Agent Code" <> xRec."Shipping Agent Code" then
                    Validate("Shipping Agent Service Code", '');
                UpdateTransLines(Rec, FieldNo("Shipping Agent Code"));
            end;
        }
        field(35; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code WHERE("Shipping Agent Code" = FIELD("Shipping Agent Code"));

            trigger OnValidate()
            begin
                TestStatusOpen;
                TransferRoute.GetShippingTime(
                  "Transfer-from Code", "Transfer-to Code",
                  "Shipping Agent Code", "Shipping Agent Service Code",
                  "Shipping Time");
                TransferRoute.CalcReceiptDate(
                  "Shipment Date",
                  "Receipt Date",
                  "Shipping Time",
                  "Outbound Whse. Handling Time",
                  "Inbound Whse. Handling Time",
                  "Transfer-from Code",
                  "Transfer-to Code",
                  "Shipping Agent Code",
                  "Shipping Agent Service Code");

                UpdateTransLines(Rec, FieldNo("Shipping Agent Service Code"));
            end;
        }
        field(36; "Shipping Time"; DateFormula)
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Time';

            trigger OnValidate()
            begin
                TestStatusOpen;
                TransferRoute.CalcReceiptDate(
                  "Shipment Date",
                  "Receipt Date",
                  "Shipping Time",
                  "Outbound Whse. Handling Time",
                  "Inbound Whse. Handling Time",
                  "Transfer-from Code",
                  "Transfer-to Code",
                  "Shipping Agent Code",
                  "Shipping Agent Service Code");

                UpdateTransLines(Rec, FieldNo("Shipping Time"));
            end;
        }
        field(37; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
        }
        field(47; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(48; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(59; "Entry/Exit Point"; Code[10])
        {
            Caption = 'Entry/Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        field(63; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(64; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(70; "Direct Transfer"; Boolean)
        {
            Caption = 'Direct Transfer';

            trigger OnValidate()
            begin
                if "Direct Transfer" then begin
                    VerifyNoOutboundWhseHandlingOnLocation("Transfer-from Code");
                    VerifyNoInboundWhseHandlingOnLocation("Transfer-to Code");
                    Validate("In-Transit Code", '');
                end;

                Modify(true);
                UpdateTransLines(Rec, FieldNo("Direct Transfer"));
            end;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDocDim;
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(5750; "Shipping Advice"; Enum "Sales Header Shipping Advice")
        {
            Caption = 'Shipping Advice';

            trigger OnValidate()
            begin
                if "Shipping Advice" <> xRec."Shipping Advice" then begin
                    TestStatusOpen;
                    WhseSourceHeader.TransHeaderVerifyChange(Rec, xRec);
                end;
            end;
        }
        field(5751; "Posting from Whse. Ref."; Integer)
        {
            Caption = 'Posting from Whse. Ref.';
        }
        field(5752; "Completely Shipped"; Boolean)
        {
            CalcFormula = Min ("Transfer Line"."Completely Shipped" WHERE("Document No." = FIELD("No."),
                                                                          "Shipment Date" = FIELD("Date Filter"),
                                                                          "Transfer-from Code" = FIELD("Location Filter"),
                                                                          "Derived From Line No." = CONST(0)));
            Caption = 'Completely Shipped';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5753; "Completely Received"; Boolean)
        {
            CalcFormula = Min ("Transfer Line"."Completely Received" WHERE("Document No." = FIELD("No."),
                                                                           "Receipt Date" = FIELD("Date Filter"),
                                                                           "Transfer-to Code" = FIELD("Location Filter"),
                                                                           "Derived From Line No." = CONST(0)));
            Caption = 'Completely Received';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5754; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(5793; "Outbound Whse. Handling Time"; DateFormula)
        {
            Caption = 'Outbound Whse. Handling Time';

            trigger OnValidate()
            begin
                TestStatusOpen;
                TransferRoute.CalcReceiptDate(
                  "Shipment Date",
                  "Receipt Date",
                  "Shipping Time",
                  "Outbound Whse. Handling Time",
                  "Inbound Whse. Handling Time",
                  "Transfer-from Code",
                  "Transfer-to Code",
                  "Shipping Agent Code",
                  "Shipping Agent Service Code");

                UpdateTransLines(Rec, FieldNo("Outbound Whse. Handling Time"));
            end;
        }
        field(5794; "Inbound Whse. Handling Time"; DateFormula)
        {
            Caption = 'Inbound Whse. Handling Time';

            trigger OnValidate()
            begin
                TestStatusOpen;
                TransferRoute.CalcReceiptDate(
                  "Shipment Date",
                  "Receipt Date",
                  "Shipping Time",
                  "Outbound Whse. Handling Time",
                  "Inbound Whse. Handling Time",
                  "Transfer-from Code",
                  "Transfer-to Code",
                  "Shipping Agent Code",
                  "Shipping Agent Service Code");

                UpdateTransLines(Rec, FieldNo("Inbound Whse. Handling Time"));
            end;
        }
        field(5796; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(8000; "Has Shipped Lines"; Boolean)
        {
            CalcFormula = Exist ("Transfer Line" WHERE("Document No." = FIELD("No."),
                                                       "Quantity Shipped" = FILTER(> 0)));
            Caption = 'Has Shipped Lines';
            FieldClass = FlowField;
        }
        field(9000; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Transfer-from Code", "Transfer-to Code", "Shipment Date", Status)
        {
        }
    }

    trigger OnDelete()
    var
        TransLine: Record "Transfer Line";
        InvtCommentLine: Record "Inventory Comment Line";
        ReservMgt: Codeunit "Reservation Management";
    begin
        TestField(Status, Status::Open);

        WhseRequest.SetRange("Source Type", DATABASE::"Transfer Line");
        WhseRequest.SetRange("Source No.", "No.");
        if not WhseRequest.IsEmpty then
            WhseRequest.DeleteAll(true);

        ReservMgt.DeleteDocumentReservation(DATABASE::"Transfer Line", 0, "No.", HideValidationDialog);

        TransLine.SetRange("Document No.", "No.");
        TransLine.DeleteAll(true);

        InvtCommentLine.SetRange("Document Type", InvtCommentLine."Document Type"::"Transfer Order");
        InvtCommentLine.SetRange("No.", "No.");
        InvtCommentLine.DeleteAll();
    end;

    trigger OnInsert()
    begin
        GetInventorySetup;
        if "No." = '' then begin
            TestNoSeries;
            NoSeriesMgt.InitSeries(GetNoSeriesCode, xRec."No. Series", "Posting Date", "No.", "No. Series");
        end;
        InitRecord;
        Validate("Shipment Date", WorkDate);
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        Text000: Label 'You cannot rename a %1.';
        Text001: Label '%1 and %2 cannot be the same in %3 %4.';
        Text002: Label 'Do you want to change %1?';
        TransferOrderPostedMsg1: Label 'Transfer order %1 was successfully posted and is now deleted.', Comment = '%1 = transfer order number e.g. Transfer order 1003 was successfully posted and is now deleted ';
        TransferRoute: Record "Transfer Route";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        PostCode: Record "Post Code";
        InvtSetup: Record "Inventory Setup";
        WhseRequest: Record "Warehouse Request";
        DimMgt: Codeunit DimensionManagement;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        WhseSourceHeader: Codeunit "Whse. Validate Source Header";
        HideValidationDialog: Boolean;
        HasInventorySetup: Boolean;
        CalledFromWhse: Boolean;
        Text007: Label 'You may have changed a dimension.\\Do you want to update the lines?';

    procedure InitRecord()
    begin
        if "Posting Date" = 0D then
            Validate("Posting Date", WorkDate);

        OnAfterInitRecord(Rec);
    end;

    procedure AssistEdit(OldTransHeader: Record "Transfer Header"): Boolean
    begin
        with TransHeader do begin
            TransHeader := Rec;
            GetInventorySetup;
            TestNoSeries;
            if NoSeriesMgt.SelectSeries(GetNoSeriesCode, OldTransHeader."No. Series", "No. Series") then begin
                NoSeriesMgt.SetSeries("No.");
                Rec := TransHeader;
                exit(true);
            end;
        end;
    end;

    local procedure TestNoSeries()
    begin
        InvtSetup.TestField("Transfer Order Nos.");
    end;

    local procedure GetNoSeriesCode(): Code[20]
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
    begin
        InvtSetup.Get();
        IsHandled := false;
        OnBeforeGetNoSeriesCode(Rec, InvtSetup, NoSeriesCode, IsHandled);
        if IsHandled then
            exit;

        NoSeriesCode := InvtSetup."Transfer Order Nos.";
        OnAfterGetNoSeriesCode(Rec, NoSeriesCode);
        exit(NoSeriesCode);
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        if OldDimSetID <> "Dimension Set ID" then begin
            Modify;
            if TransferLinesExist then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    local procedure GetInventorySetup()
    begin
        if not HasInventorySetup then begin
            InvtSetup.Get();
            HasInventorySetup := true;
        end;
    end;

    procedure UpdateTransLines(TransferHeader: Record "Transfer Header"; FieldID: Integer)
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Document No.", "No.");
        TransferLine.SetFilter("Item No.", '<>%1', '');
        if TransferLine.FindSet then begin
            TransferLine.LockTable();
            repeat
                case FieldID of
                    FieldNo("In-Transit Code"):
                        TransferLine.Validate("In-Transit Code", TransferHeader."In-Transit Code");
                    FieldNo("Transfer-from Code"):
                        begin
                            TransferLine.Validate("Transfer-from Code", TransferHeader."Transfer-from Code");
                            TransferLine.Validate("Shipping Agent Code", TransferHeader."Shipping Agent Code");
                            TransferLine.Validate("Shipping Agent Service Code", TransferHeader."Shipping Agent Service Code");
                            TransferLine.Validate("Shipment Date", TransferHeader."Shipment Date");
                            TransferLine.Validate("Receipt Date", TransferHeader."Receipt Date");
                            TransferLine.Validate("Shipping Time", TransferHeader."Shipping Time");
                        end;
                    FieldNo("Transfer-to Code"):
                        begin
                            TransferLine.Validate("Transfer-to Code", TransferHeader."Transfer-to Code");
                            TransferLine.Validate("Shipping Agent Code", TransferHeader."Shipping Agent Code");
                            TransferLine.Validate("Shipping Agent Service Code", TransferHeader."Shipping Agent Service Code");
                            TransferLine.Validate("Shipment Date", TransferHeader."Shipment Date");
                            TransferLine.Validate("Receipt Date", TransferHeader."Receipt Date");
                            TransferLine.Validate("Shipping Time", TransferHeader."Shipping Time");
                        end;
                    FieldNo("Shipping Agent Code"):
                        begin
                            TransferLine.Validate("Shipping Agent Code", TransferHeader."Shipping Agent Code");
                            TransferLine.BlockDynamicTracking(true);
                            TransferLine.Validate("Shipping Agent Service Code", TransferHeader."Shipping Agent Service Code");
                            TransferLine.Validate("Shipment Date", TransferHeader."Shipment Date");
                            TransferLine.Validate("Receipt Date", TransferHeader."Receipt Date");
                            TransferLine.Validate("Shipping Time", TransferHeader."Shipping Time");
                            TransferLine.BlockDynamicTracking(false);
                            TransferLine.DateConflictCheck;
                        end;
                    FieldNo("Shipping Agent Service Code"):
                        begin
                            TransferLine.BlockDynamicTracking(true);
                            TransferLine.Validate("Shipping Agent Service Code", TransferHeader."Shipping Agent Service Code");
                            TransferLine.Validate("Shipment Date", TransferHeader."Shipment Date");
                            TransferLine.Validate("Receipt Date", TransferHeader."Receipt Date");
                            TransferLine.Validate("Shipping Time", TransferHeader."Shipping Time");
                            TransferLine.BlockDynamicTracking(false);
                            TransferLine.DateConflictCheck;
                        end;
                    FieldNo("Shipment Date"):
                        begin
                            TransferLine.BlockDynamicTracking(true);
                            TransferLine.Validate("Shipment Date", TransferHeader."Shipment Date");
                            TransferLine.Validate("Receipt Date", TransferHeader."Receipt Date");
                            TransferLine.Validate("Shipping Time", TransferHeader."Shipping Time");
                            TransferLine.BlockDynamicTracking(false);
                            TransferLine.DateConflictCheck;
                        end;
                    FieldNo("Receipt Date"), FieldNo("Shipping Time"):
                        begin
                            TransferLine.BlockDynamicTracking(true);
                            TransferLine.Validate("Shipping Time", TransferHeader."Shipping Time");
                            TransferLine.Validate("Receipt Date", TransferHeader."Receipt Date");
                            TransferLine.BlockDynamicTracking(false);
                            TransferLine.DateConflictCheck;
                        end;
                    FieldNo("Outbound Whse. Handling Time"):
                        TransferLine.Validate("Outbound Whse. Handling Time", TransferHeader."Outbound Whse. Handling Time");
                    FieldNo("Inbound Whse. Handling Time"):
                        TransferLine.Validate("Inbound Whse. Handling Time", TransferHeader."Inbound Whse. Handling Time");
                    FieldNo(Status):
                        TransferLine.Validate(Status, TransferHeader.Status);
                    FieldNo("Direct Transfer"):
                        begin
                            TransferLine.Validate("In-Transit Code", TransferHeader."In-Transit Code");
                            TransferLine.Validate("Item No.", TransferLine."Item No.");
                        end;
                    else
                        OnUpdateTransLines(TransferLine, TransferHeader, FieldID);
                end;
                TransferLine.Modify(true);
            until TransferLine.Next = 0;
        end;
    end;

    procedure ShouldDeleteOneTransferOrder(var TransLine2: Record "Transfer Line"): Boolean
    var
        IsHandled: Boolean;
        ShouldDelete: Boolean;
    begin
        IsHandled := false;
        OnBeforeShouldDeleteOneTransferOrder(TransLine2, ShouldDelete, IsHandled);
        if IsHandled then
            exit(ShouldDelete);

        if TransLine2.Find('-') then
            repeat
                if (TransLine2.Quantity <> TransLine2."Quantity Shipped") or
                   (TransLine2.Quantity <> TransLine2."Quantity Received") or
                   (TransLine2."Quantity (Base)" <> TransLine2."Qty. Shipped (Base)") or
                   (TransLine2."Quantity (Base)" <> TransLine2."Qty. Received (Base)") or
                   (TransLine2."Quantity Shipped" <> TransLine2."Quantity Received") or
                   (TransLine2."Qty. Shipped (Base)" <> TransLine2."Qty. Received (Base)")
                then
                    exit(false);
            until TransLine2.Next = 0;

        exit(true);
    end;

    procedure DeleteOneTransferOrder(var TransHeader2: Record "Transfer Header"; var TransLine2: Record "Transfer Line")
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        WhseRequest: Record "Warehouse Request";
        InvtCommentLine: Record "Inventory Comment Line";
        No: Code[20];
    begin
        No := TransHeader2."No.";

        WhseRequest.SetRange("Source Type", DATABASE::"Transfer Line");
        WhseRequest.SetRange("Source No.", No);
        if not WhseRequest.IsEmpty then
            WhseRequest.DeleteAll(true);

        InvtCommentLine.SetRange("Document Type", InvtCommentLine."Document Type"::"Transfer Order");
        InvtCommentLine.SetRange("No.", No);
        InvtCommentLine.DeleteAll();

        ItemChargeAssgntPurch.SetCurrentKey(
          "Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. Type", ItemChargeAssgntPurch."Applies-to Doc. Type"::"Transfer Receipt");
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. No.", TransLine2."Document No.");
        ItemChargeAssgntPurch.DeleteAll();

        OnBeforeTransLineDeleteAll(TransHeader2, TransLine2);

        if TransLine2.Find('-') then
            TransLine2.DeleteAll();

        TransHeader2.Delete();
        if not HideValidationDialog then
            Message(TransferOrderPostedMsg1, No);
    end;

    procedure TestStatusOpen()
    begin
        if not CalledFromWhse then
            TestField(Status, Status::Open);
    end;

    procedure CalledFromWarehouse(CalledFromWhse2: Boolean)
    begin
        CalledFromWhse := CalledFromWhse2;
    end;

    procedure CreateInvtPutAwayPick()
    var
        WhseRequest: Record "Warehouse Request";
    begin
        TestField(Status, Status::Released);

        WhseRequest.Reset();
        WhseRequest.SetCurrentKey("Source Document", "Source No.");
        WhseRequest.SetFilter(
          "Source Document", '%1|%2',
          WhseRequest."Source Document"::"Inbound Transfer",
          WhseRequest."Source Document"::"Outbound Transfer");
        WhseRequest.SetRange("Source No.", "No.");
        REPORT.RunModal(REPORT::"Create Invt Put-away/Pick/Mvmt", true, false, WhseRequest);
    end;

    procedure ShowDocDim()
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2', TableCaption, "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        if OldDimSetID <> "Dimension Set ID" then begin
            Modify;
            if TransferLinesExist then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    local procedure TransferLinesExist(): Boolean
    begin
        TransLine.Reset();
        TransLine.SetRange("Document No.", "No.");
        exit(TransLine.FindFirst);
    end;

    procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        NewDimSetID: Integer;
        ShippedLineDimChangeConfirmed: Boolean;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        // Update all lines with changed dimensions.

        if NewParentDimSetID = OldParentDimSetID then
            exit;
        if not (HideValidationDialog or ConfirmManagement.GetResponseOrDefault(Text007, true)) then
            exit;

        TransLine.Reset();
        TransLine.SetRange("Document No.", "No.");
        TransLine.LockTable();
        if TransLine.Find('-') then
            repeat
                NewDimSetID := DimMgt.GetDeltaDimSetID(TransLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if TransLine."Dimension Set ID" <> NewDimSetID then begin
                    TransLine."Dimension Set ID" := NewDimSetID;

                    VerifyShippedLineDimChange(ShippedLineDimChangeConfirmed);

                    DimMgt.UpdateGlobalDimFromDimSetID(
                      TransLine."Dimension Set ID", TransLine."Shortcut Dimension 1 Code", TransLine."Shortcut Dimension 2 Code");
                    TransLine.Modify();
                end;
            until TransLine.Next = 0;
    end;

    local procedure VerifyShippedLineDimChange(var ShippedLineDimChangeConfirmed: Boolean)
    begin
        if TransLine.IsShippedDimChanged then
            if not ShippedLineDimChangeConfirmed then
                ShippedLineDimChangeConfirmed := TransLine.ConfirmShippedDimChange;
    end;

    procedure CheckBeforePost()
    begin
        TestField("Transfer-from Code");
        TestField("Transfer-to Code");
        if "Transfer-from Code" = "Transfer-to Code" then
            Error(
              Text001,
              FieldCaption("Transfer-from Code"), FieldCaption("Transfer-to Code"),
              TableCaption, "No.");

        if not "Direct Transfer" then
            TestField("In-Transit Code")
        else begin
            VerifyNoOutboundWhseHandlingOnLocation("Transfer-from Code");
            VerifyNoInboundWhseHandlingOnLocation("Transfer-to Code");
        end;
        TestField(Status, Status::Released);
        TestField("Posting Date");

        OnAfterCheckBeforePost(Rec);
    end;

    procedure CheckInvtPostingSetup()
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        InventoryPostingSetup.SetRange("Location Code", "Transfer-from Code");
        InventoryPostingSetup.FindFirst;
        InventoryPostingSetup.SetRange("Location Code", "Transfer-to Code");
        InventoryPostingSetup.FindFirst;
    end;

    procedure HasShippedItems(): Boolean
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Document No.", "No.");
        TransferLine.SetFilter("Item No.", '<>%1', '');
        TransferLine.SetFilter("Quantity Shipped", '>%1', 0);
        exit(not TransferLine.IsEmpty);
    end;

    procedure HasTransferLines(): Boolean
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Document No.", "No.");
        TransferLine.SetFilter("Item No.", '<>%1', '');
        exit(not TransferLine.IsEmpty);
    end;

    procedure GetReceiptLines()
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        TempPurchRcptHeader: Record "Purch. Rcpt. Header" temporary;
        PostedPurchaseReceipts: Page "Posted Purchase Receipts";
    begin
        PurchRcptHeader.SetRange("Location Code", "Transfer-from Code");
        PostedPurchaseReceipts.SetTableView(PurchRcptHeader);
        PostedPurchaseReceipts.LookupMode := true;
        if PostedPurchaseReceipts.RunModal = ACTION::LookupOK then begin
            PostedPurchaseReceipts.GetSelectedRecords(TempPurchRcptHeader);
            CreateTransferLinesFromSelectedPurchReceipts(TempPurchRcptHeader);
        end;
    end;

    local procedure CreateTransferLinesFromSelectedPurchReceipts(var TempPurchRcptHeader: Record "Purch. Rcpt. Header" temporary)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TempPurchRcptLine: Record "Purch. Rcpt. Line" temporary;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        PostedPurchaseReceiptLines: Page "Posted Purchase Receipt Lines";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(TempPurchRcptHeader);
        PurchRcptLine.SetFilter(
          "Document No.",
          SelectionFilterManagement.GetSelectionFilter(RecRef, TempPurchRcptHeader.FieldNo("No.")));
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.SetRange("Location Code", "Transfer-from Code");
        PostedPurchaseReceiptLines.SetTableView(PurchRcptLine);
        PostedPurchaseReceiptLines.LookupMode := true;
        if PostedPurchaseReceiptLines.RunModal = ACTION::LookupOK then begin
            PostedPurchaseReceiptLines.GetSelectedRecords(TempPurchRcptLine);
            CreateTransferLinesFromSelectedReceiptLines(TempPurchRcptLine);
        end;
    end;

    local procedure CreateTransferLinesFromSelectedReceiptLines(var PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        TransferLine: Record "Transfer Line";
        LineNo: Integer;
    begin
        TransferLine.SetRange("Document No.", "No.");
        if TransferLine.FindLast then;
        LineNo := TransferLine."Line No.";

        if PurchRcptLine.FindSet then
            repeat
                LineNo := LineNo + 10000;
                AddTransferLineFromReceiptLine(PurchRcptLine, LineNo);
            until PurchRcptLine.Next = 0;
    end;

    local procedure AddTransferLineFromReceiptLine(PurchRcptLine: Record "Purch. Rcpt. Line"; LineNo: Integer)
    var
        TransferLine: Record "Transfer Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        TransferLine."Document No." := "No.";
        TransferLine."Line No." := LineNo;
        TransferLine.Validate("Item No.", PurchRcptLine."No.");
        TransferLine.Validate("Variant Code", PurchRcptLine."Variant Code");
        TransferLine.Validate(Quantity, PurchRcptLine.Quantity);
        TransferLine.Validate("Unit of Measure Code", PurchRcptLine."Unit of Measure Code");
        TransferLine."Shortcut Dimension 1 Code" := PurchRcptLine."Shortcut Dimension 1 Code";
        TransferLine."Shortcut Dimension 2 Code" := PurchRcptLine."Shortcut Dimension 2 Code";
        TransferLine."Dimension Set ID" := PurchRcptLine."Dimension Set ID";
        OnAddTransferLineFromReceiptLineOnBeforeTransferLineInsert(TransferLine, PurchRcptLine);
        TransferLine.Insert(true);

        PurchRcptLine.FilterPstdDocLnItemLedgEntries(ItemLedgerEntry);
        ItemTrackingDocMgt.CopyItemLedgerEntriesToTemp(TempItemLedgerEntry, ItemLedgerEntry);
        ItemTrackingMgt.CopyItemLedgEntryTrkgToTransferLine(TempItemLedgerEntry, TransferLine);

        OnAfterAddTransferLineFromReceiptLine(TransferLine, PurchRcptLine, TempItemLedgerEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateTransLines(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"; FieldID: Integer)
    begin
    end;

    procedure VerifyNoOutboundWhseHandlingOnLocation(LocationCode: Code[10])
    var
        Location: Record Location;
    begin
        if not Location.Get(LocationCode) then
            exit;

        Location.TestField("Require Pick", false);
        Location.TestField("Require Shipment", false);
    end;

    procedure VerifyNoInboundWhseHandlingOnLocation(LocationCode: Code[10])
    var
        Location: Record Location;
    begin
        if not Location.Get(LocationCode) then
            exit;

        Location.TestField("Require Put-away", false);
        Location.TestField("Require Receive", false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddTransferLineFromReceiptLineOnBeforeTransferLineInsert(var TransferLine: Record "Transfer Line"; PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddTransferLineFromReceiptLine(var TransferLine: Record "Transfer Line"; var PurchRcptLine: Record "Purch. Rcpt. Line"; var TempItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckBeforePost(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetNoSeriesCode(var TransferHeader: Record "Transfer Header"; var NoSeriesCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetTransferRoute(var TransferHeader: Record "Transfer Header"; TransferRoute: Record "Transfer Route");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRecord(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var TransferHeader: Record "Transfer Header"; var xTransferHeader: Record "Transfer Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNoSeriesCode(var TransferHeader: Record "Transfer Header"; InventorySetup: Record "Inventory Setup"; var NoSeriesCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShouldDeleteOneTransferOrder(var TransferLine: record "Transfer Line"; var ShouldDelete: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransLineDeleteAll(TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var TransferHeader: Record "Transfer Header"; var xTransferHeader: Record "Transfer Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTransferFromCode(var TransferHeader: Record "Transfer Header"; var xTransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTransferToCode(var TransferHeader: Record "Transfer Header"; var xTransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;
}

