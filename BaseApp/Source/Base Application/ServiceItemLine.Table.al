table 5901 "Service Item Line"
{
    Caption = 'Service Item Line';
    DrillDownPageID = "Service Item Lines";
    LookupPageID = "Service Item Lines";
    Permissions = TableData "Loaner Entry" = rimd,
                  TableData "Service Order Allocation" = rimd;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
            TableRelation = "Service Header"."No." WHERE("Document Type" = FIELD("Document Type"));

            trigger OnValidate()
            begin
                CreateDim(
                  DATABASE::"Service Item", "Service Item No.",
                  DATABASE::"Service Item Group", "Service Item Group Code",
                  DATABASE::"Responsibility Center", "Responsibility Center");
            end;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Service Item No."; Code[20])
        {
            Caption = 'Service Item No.';
            TableRelation = "Service Item"."No.";

            trigger OnValidate()
            var
                Cust: Record Customer;
                ConfirmManagement: Codeunit "Confirm Management";
                ServContractList: Page "Serv. Contr. List (Serv. Item)";
                IsHandled: Boolean;
            begin
                if "Loaner No." <> '' then
                    Error(Text055, FieldCaption("Service Item No."),
                      FieldCaption("Loaner No."), "Loaner No.");

                if "Service Item No." <> xRec."Service Item No." then begin
                    if CheckServLineExist then
                        Error(
                          Text011,
                          FieldCaption("Service Item No."), TableCaption, ServLine.TableCaption);
                end else begin
                    CreateDim(
                      DATABASE::"Service Item", "Service Item No.",
                      DATABASE::"Service Item Group", "Service Item Group Code",
                      DATABASE::"Responsibility Center", "Responsibility Center");

                    if ServItem.Get("Service Item No.") then begin
                        SetServItemInfo(ServItem);
                        if "Contract No." = '' then
                            Validate("Service Price Group Code", ServItem."Service Price Group Code");
                        "Service Item Group Code" := ServItem."Service Item Group Code";
                    end;

                    exit;
                end;

                if "Service Item No." = '' then begin
                    if xRec."Service Item No." <> "Service Item No." then begin
                        Validate("Warranty Starting Date (Parts)", 0D);
                        Validate("Warranty Starting Date (Labor)", 0D);
                        Validate("Contract No.", '');
                        Validate("Serial No.", '');
                    end;
                    exit;
                end;

                ServContractExist := false;
                ServHeader.Get("Document Type", "Document No.");
                if ServItem.Get("Service Item No.") then begin
                    if ServHeader."Customer No." <> ServItem."Customer No." then
                        Error(
                          Text012,
                          ServItem.TableCaption, "Service Item No.", ServHeader.FieldCaption("Customer No."), ServHeader."Customer No.");

                    if ServHeader."Contract No." <> '' then begin
                        ServHeader.TestField("Order Date");
                        ServContractLine.Reset();
                        ServContractLine.SetRange("Contract Type", ServContractLine."Contract Type"::Contract);
                        ServContractLine.SetRange("Contract No.", ServHeader."Contract No.");
                        ServContractLine.SetRange("Service Item No.", "Service Item No.");
                        if not ServContractLine.FindFirst then
                            Error(Text050, ServHeader."Contract No.", "Service Item No.");
                        IsHandled := false;
                        OnValidateServiceItemNoOnBeforeValidateServicePeriod(Rec, xRec, CurrFieldNo, IsHandled);
                        if not IsHandled then
                            ServContractLine.ValidateServicePeriod(ServHeader."Order Date");
                        ServContractExist := true;
                    end;

                    if ServHeader."Contract No." = '' then begin
                        ServContractLine.Reset();
                        ServContractLine.FilterGroup(2);
                        ServContractLine.SetCurrentKey("Service Item No.", "Contract Status");
                        ServContractLine.SetRange("Service Item No.", ServItem."No.");
                        ServContractLine.SetRange("Contract Status", ServContractLine."Contract Status"::Signed);
                        ServContractLine.SetRange("Contract Type", ServContractLine."Contract Type"::Contract);
                        ServContractLine.SetRange("Customer No.", ServHeader."Customer No.");
                        ServContractLine.SetFilter("Starting Date", '<=%1', ServHeader."Order Date");
                        ServContractLine.SetFilter("Contract Expiration Date", '>=%1 | =%2', ServHeader."Order Date", 0D);
                        ServContractLine.FilterGroup(0);

                        if ServContractLine.Find('-') then
                            if ServContractLine.Next > 0 then begin
                                if ConfirmManagement.GetResponse(
                                     StrSubstNo(Text047, "Service Item No."), true)
                                then begin
                                    ServContractList.SetTableView(ServContractLine);
                                    ServContractList.LookupMode(true);
                                    if ServContractList.RunModal = ACTION::LookupOK then begin
                                        ServContractList.GetRecord(ServContractLine);
                                        ServContractExist := true;
                                    end;
                                end;
                            end else begin
                                ServContractLine.FindFirst;
                                ServContractExist := true;
                            end;
                    end;

                    if (ServItem."Ship-to Code" <> ServHeader."Ship-to Code") and not HideDialogBox then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(
                               Text040, ServItem.TableCaption,
                               FieldCaption("Ship-to Code"), Cust.TableCaption), true)
                        then begin
                            "Service Item No." := xRec."Service Item No.";
                            exit;
                        end;
                    "Ship-to Code" := ServItem."Ship-to Code";
                    SetServItemInfo(ServItem);

                    if ServContractExist then
                        Validate("Contract No.", ServContractLine."Contract No.")
                    else
                        Validate("Contract No.", '');

                    if "Contract No." = '' then
                        Validate("Service Price Group Code", ServItem."Service Price Group Code");
                    Validate("Service Item Group Code", ServItem."Service Item Group Code");
                end;

                if ServItemLine.Get("Document Type", "Document No.", "Line No.") then begin
                    UseServItemLineAsxRec := true;
                    Modify(true);
                end;
                UpdateResponseTimeHours;
                CreateDim(
                  DATABASE::"Service Item", "Service Item No.",
                  DATABASE::"Service Item Group", "Service Item Group Code",
                  DATABASE::"Responsibility Center", "Responsibility Center");
            end;
        }
        field(4; "Service Item Group Code"; Code[10])
        {
            Caption = 'Service Item Group Code';
            TableRelation = "Service Item Group".Code;

            trigger OnValidate()
            begin
                if "Service Item Group Code" <> xRec."Service Item Group Code" then begin
                    if "Service Item No." <> '' then begin
                        ServItem.Get("Service Item No.");
                        TestField("Service Item Group Code", ServItem."Service Item Group Code");
                    end;
                    if ServItemGr.Get("Service Item Group Code") then begin
                        if ("Item No." = '') and (Description = '') then
                            Description := ServItemGr.Description;
                        if ServItem."Service Price Group Code" = '' then
                            if "Contract No." = '' then
                                Validate("Service Price Group Code", ServItemGr."Default Serv. Price Group Code");
                    end;
                end;
                UpdateResponseTimeHours;

                CreateDim(
                  DATABASE::"Service Item Group", "Service Item Group Code",
                  DATABASE::"Service Item", "Service Item No.",
                  DATABASE::"Responsibility Center", "Responsibility Center");
            end;
        }
        field(5; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item."No.";

            trigger OnValidate()
            begin
                if "Service Item No." <> '' then
                    Error(Text016,
                      FieldCaption("Item No."), FieldCaption("Service Item No."));
                if "Item No." <> '' then begin
                    Item.Get("Item No.");
                    Validate("Service Item Group Code", Item."Service Item Group");
                    GetServHeader;
                    if (ServHeader."Language Code" = '') or not GetItemTranslation then begin
                        Description := Item.Description;
                        "Description 2" := Item."Description 2";
                    end;
                    OnAfterAssignItemValues(Rec, xRec, Item, ServHeader, CurrFieldNo);
                end else begin
                    Description := '';
                    "Description 2" := '';
                end;
                UpdateResponseTimeHours;
            end;
        }
        field(6; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateSerialNo(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Serial No." <> xRec."Serial No." then
                    if "Service Item No." <> '' then
                        Error(
                          Text016,
                          FieldCaption("Serial No."), FieldCaption("Service Item No."));
                UpdateResponseTimeHours;

                if "Serial No." = '' then
                    exit;

                GetServHeader;
                ServItem.Reset();
                ServItem.SetCurrentKey("Customer No.", "Ship-to Code", "Item No.", "Serial No.");
                ServItem.SetRange("Customer No.", ServHeader."Customer No.");
                ServItem.SetRange("Ship-to Code", ServHeader."Ship-to Code");
                ServItem.SetRange("Item No.", "Item No.");
                ServItem.SetRange("Serial No.", "Serial No.");
                NoOfRec := ServItem.Count();
                case true of
                    NoOfRec = 1:
                        begin
                            ServItem.FindFirst;
                            Validate("Service Item No.", ServItem."No.");
                        end;
                    NoOfRec > 1:
                        if PAGE.RunModal(0, ServItem) = ACTION::LookupOK then
                            Validate("Service Item No.", ServItem."No.");
                end;
            end;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                UpdateResponseTimeHours;
                Validate("Document No.");
            end;
        }
        field(8; "Description 2"; Text[50])
        {
            Caption = 'Description 2';

            trigger OnValidate()
            begin
                UpdateResponseTimeHours;
            end;
        }
        field(9; "Repair Status Code"; Code[10])
        {
            Caption = 'Repair Status Code';
            TableRelation = "Repair Status";

            trigger OnValidate()
            begin
                UpdateResponseTimeHours;
                if "Repair Status Code" <> '' then begin
                    RepairStatus.Get("Repair Status Code");
                    if RepairStatus2.Get(xRec."Repair Status Code") then
                        if (not RepairStatus.Finished and RepairStatus2.Finished) or
                           (not RepairStatus."Quote Finished" and RepairStatus2."Quote Finished")
                        then begin
                            "Finishing Date" := 0D;
                            "Finishing Time" := 0T;
                        end;

                    if ("Document Type" = "Document Type"::Order) and
                       RepairStatus."Quote Finished"
                    then
                        Error(Text035, RepairStatus.TableCaption, RepairStatus.Code);

                    if ("Document Type" = "Document Type"::Quote) and
                       RepairStatus.Finished
                    then
                        Error(Text036, RepairStatus.TableCaption, RepairStatus.Code);
                    if RepairStatus.Initial then begin
                        "Starting Date" := 0D;
                        "Starting Time" := 0T;
                        "Finishing Date" := 0D;
                        "Finishing Time" := 0T;
                        UpdateStartFinishDateTime("Document Type", "Document No.", "Line No.", "Starting Date", "Starting Time",
                          "Finishing Date", "Finishing Time", false);
                        ServOrderAlloc.SetFilters(Rec);
                        ServOrderAlloc.ModifyAll("Service Started", false, false);
                    end;

                    if RepairStatus."In Process" then begin
                        GetServHeader;
                        if ServHeader."Order Date" > WorkDate then begin
                            "Starting Date" := ServHeader."Order Date";
                            Validate("Starting Time", ServHeader."Order Time");
                        end else begin
                            "Starting Date" := WorkDate;
                            if (ServHeader."Order Date" = "Starting Date") and (ServHeader."Order Time" > Time) then
                                Validate("Starting Time", ServHeader."Order Time")
                            else
                                Validate("Starting Time", Time);
                        end;
                        ServOrderAlloc.SetFilters(Rec);
                        ServOrderAlloc.ModifyAll("Service Started", true, false);
                    end;

                    if RepairStatus.Finished then begin
                        ServMgtSetup.Get();
                        if ServMgtSetup."Fault Reason Code Mandatory" then
                            TestField("Fault Reason Code");
                        GetServHeader;
                        CalculateDates;
                        ServOrderAlloc.SetFilters(Rec);
                        ServOrderAlloc.ModifyAll(Status, ServOrderAlloc.Status::Finished, false);
                    end;

                    if RepairStatus."Quote Finished" then begin
                        GetServHeader;
                        CalculateDates;
                    end;

                    if RepairStatus."Partly Serviced" or RepairStatus.Referred then begin
                        ServOrderAlloc.SetFilters(Rec);
                        if ServOrderAlloc.Find('-') then
                            repeat
                                if RepairStatus.Referred and RepairStatus2.Initial then
                                    ServOrderAlloc."Service Started" := false;
                                ServOrderAlloc.Status := ServOrderAlloc.Status::"Reallocation Needed";
                                ServOrderAlloc."Reason Code" := '';
                                ServOrderAlloc.Modify();
                            until ServOrderAlloc.Next = 0;
                    end;

                    RepairStatusPriority := RepairStatus.Priority;
                    UseLineNo := "Line No.";
                    ServItemLine.Reset();
                    ServItemLine.SetRange("Document Type", "Document Type");
                    ServItemLine.SetRange("Document No.", "Document No.");
                    ServItemLine.SetFilter("Line No.", '<>%1', "Line No.");
                    ServItemLine.SetFilter("Repair Status Code", '<>%1', '');
                    if ServItemLine.Find('-') then
                        repeat
                            RepairStatus2.Get(ServItemLine."Repair Status Code");
                            if RepairStatus2.Priority < RepairStatusPriority then begin
                                RepairStatusPriority := RepairStatus2.Priority;
                                UseLineNo := ServItemLine."Line No.";
                            end;
                        until ServItemLine.Next = 0;
                    if "Line No." <> UseLineNo then begin
                        ServItemLine.Get("Document Type", "Document No.", UseLineNo);
                        RepairStatus.Get(ServItemLine."Repair Status Code");
                    end else
                        RepairStatus.Get("Repair Status Code");
                    ServHeader2.Get("Document Type", "Document No.");
                    ServHeader3 := ServHeader2;
                    if ServHeader2.Status <> RepairStatus."Service Order Status" then begin
                        ServHeader2.SetValidatingFromLines(true);
                        if ServHeader2."Finishing Date" = 0D then
                            ServHeader2.Validate("Finishing Date", "Finishing Date");
                        ServHeader2.Validate(Status, RepairStatus."Service Order Status");
                        if not (ServHeader2.Status = ServHeader2.Status::Finished) then begin
                            ServHeader2."Finishing Date" := 0D;
                            ServHeader2."Finishing Time" := 0T;
                            ServHeader2."Service Time (Hours)" := 0;
                        end;
                        ServHeader2.UpdateServiceOrderChangeLog(ServHeader3);
                        ServHeader2.Modify();
                        if ServHeader2.Status = ServHeader2.Status::Finished then
                            UpdateStartFinishDateTime("Document Type", "Document No.", "Line No.", "Starting Date", "Starting Time",
                              "Finishing Date", "Finishing Time", false);
                    end;
                end;
            end;
        }
        field(10; Priority; Option)
        {
            Caption = 'Priority';
            OptionCaption = 'Low,Medium,High';
            OptionMembers = Low,Medium,High;
        }
        field(11; "Response Time (Hours)"; Decimal)
        {
            Caption = 'Response Time (Hours)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if ("Response Time (Hours)" <> xRec."Response Time (Hours)") or ("Response Time (Hours)" = 0) then begin
                    SkipResponseTimeHrsUpdate := true;
                    GetServHeader;
                    CalculateResponseDateTime(ServHeader."Order Date", ServHeader."Order Time");
                end else
                    UpdateResponseTimeHours;
            end;
        }
        field(12; "Response Date"; Date)
        {
            Caption = 'Response Date';

            trigger OnValidate()
            begin
                SkipResponseTimeHrsUpdate := true;
                if "Response Date" <> xRec."Response Date" then begin
                    GetServHeader;
                    if "Response Date" <> 0D then begin
                        if "Response Date" < ServHeader."Order Date" then
                            Error(
                              Text022,
                              FieldCaption("Response Date"), ServHeader.TableCaption,
                              ServHeader.FieldCaption("Order Date"));
                        if "Response Date" = ServHeader."Order Date" then
                            if Time < ServHeader."Order Time" then
                                "Response Time" := ServHeader."Order Time"
                            else
                                "Response Time" := Time;
                    end else
                        "Response Time" := 0T;

                    "Response Time (Hours)" := 0;
                end;
            end;
        }
        field(13; "Response Time"; Time)
        {
            Caption = 'Response Time';

            trigger OnValidate()
            begin
                SkipResponseTimeHrsUpdate := true;
                if "Response Time" <> xRec."Response Time" then begin
                    GetServHeader;
                    if ("Response Date" = ServHeader."Order Date") and
                       ("Response Time" < ServHeader."Order Time")
                    then
                        Error(
                          Text022,
                          FieldCaption("Response Time"), ServHeader.TableCaption,
                          ServHeader.FieldCaption("Order Time"));

                    "Response Time (Hours)" := 0;
                end;
            end;
        }
        field(14; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                SkipResponseTimeHrsUpdate := true;
                GetServHeader;
                if "Starting Date" <> 0D then begin
                    if "Starting Date" < ServHeader."Order Date" then
                        Error(
                          Text022,
                          FieldCaption("Starting Date"), ServHeader.TableCaption,
                          ServHeader.FieldCaption("Order Date"));

                    if ("Starting Date" > ServHeader."Finishing Date") and
                       (ServHeader."Finishing Date" <> 0D)
                    then
                        Error(
                          Text018,
                          FieldCaption("Starting Date"),
                          ServHeader.TableCaption,
                          ServHeader.FieldCaption("Finishing Date"));

                    if "Starting Date" <> xRec."Starting Date" then begin
                        "Finishing Date" := 0D;
                        "Finishing Time" := 0T;
                    end;

                    if ("Starting Date" = ServHeader."Order Date") and
                       (Time < ServHeader."Order Time")
                    then
                        Validate("Starting Time", ServHeader."Order Time")
                    else
                        Validate("Starting Time", Time);
                end else begin
                    "Starting Time" := 0T;
                    Validate("Finishing Date", 0D);
                end;
            end;
        }
        field(15; "Starting Time"; Time)
        {
            Caption = 'Starting Time';

            trigger OnValidate()
            begin
                SkipResponseTimeHrsUpdate := true;
                TestField("Starting Date");
                if "Starting Time" <> 0T then begin
                    GetServHeader;
                    if ("Starting Date" = ServHeader."Order Date") and
                       ("Starting Time" < ServHeader."Order Time")
                    then
                        Error(
                          Text022,
                          FieldCaption("Starting Time"), ServHeader.TableCaption,
                          ServHeader.FieldCaption("Order Time"));

                    if ("Starting Time" > "Finishing Time") and
                       ("Finishing Time" <> 0T) and
                       ("Starting Date" = "Finishing Date")
                    then
                        Error(Text020,
                          FieldCaption("Starting Time"), FieldCaption("Finishing Time"));

                    UpdateStartFinishDateTime("Document Type", "Document No.", "Line No.", "Starting Date",
                      "Starting Time", "Finishing Date", "Finishing Time", false);
                end else begin
                    "Finishing Date" := 0D;
                    "Finishing Time" := 0T;
                    UpdateStartFinishDateTime("Document Type", "Document No.", "Line No.", "Starting Date", "Starting Time",
                      "Finishing Date", "Finishing Time", false);
                end;
            end;
        }
        field(16; "Finishing Date"; Date)
        {
            Caption = 'Finishing Date';

            trigger OnValidate()
            begin
                SkipResponseTimeHrsUpdate := true;
                GetServHeader;
                if "Finishing Date" <> 0D then begin
                    if "Finishing Date" < ServHeader."Order Date" then
                        Error(
                          Text022,
                          FieldCaption("Finishing Date"), ServHeader.TableCaption,
                          ServHeader.FieldCaption("Order Date"));

                    if "Finishing Date" < "Starting Date" then
                        Error(
                          Text019,
                          FieldCaption("Finishing Date"), FieldCaption("Starting Date"));
                    if ("Starting Date" = "Finishing Date") and ("Starting Time" > Time) then
                        Validate("Finishing Time", "Starting Time")
                    else
                        Validate("Finishing Time", Time);
                    UpdateStartFinishDateTime("Document Type", "Document No.", "Line No.", "Starting Date", "Starting Time",
                      "Finishing Date", "Finishing Time", false);
                end else begin
                    "Finishing Time" := 0T;
                    UpdateStartFinishDateTime("Document Type", "Document No.", "Line No.", "Starting Date", "Starting Time",
                      "Finishing Date", "Finishing Time", false);
                end;
            end;
        }
        field(17; "Finishing Time"; Time)
        {
            Caption = 'Finishing Time';

            trigger OnValidate()
            begin
                SkipResponseTimeHrsUpdate := true;
                TestField("Finishing Date");
                GetServHeader;
                if "Finishing Time" <> 0T then begin
                    if ("Finishing Date" = "Starting Date") and
                       ("Finishing Time" < "Starting Time")
                    then
                        Error(
                          Text022,
                          FieldCaption("Finishing Time"),
                          FieldCaption("Starting Time"));
                    UpdateStartFinishDateTime("Document Type", "Document No.", "Line No.", "Starting Date", "Starting Time",
                      "Finishing Date", "Finishing Time", false);
                end;
            end;
        }
        field(18; "Service Shelf No."; Code[10])
        {
            Caption = 'Service Shelf No.';
            TableRelation = "Service Shelf";
        }
        field(19; "Warranty Starting Date (Parts)"; Date)
        {
            Caption = 'Warranty Starting Date (Parts)';

            trigger OnValidate()
            begin
                if "Service Item No." <> '' then begin
                    ServItem.Get("Service Item No.");
                    if "Warranty Starting Date (Parts)" <> ServItem."Warranty Starting Date (Parts)" then
                        Error(Text023, ServItem.TableCaption);
                end;

                if "Warranty Starting Date (Parts)" <> 0D then begin
                    ServMgtSetup.Get();
                    "Warranty Ending Date (Parts)" := CalcDate(ServMgtSetup."Default Warranty Duration", "Warranty Starting Date (Parts)");
                    "Warranty % (Parts)" := ServMgtSetup."Warranty Disc. % (Parts)";
                end else begin
                    "Warranty Ending Date (Parts)" := 0D;
                    "Warranty % (Parts)" := 0;
                end;
            end;
        }
        field(20; "Warranty Ending Date (Parts)"; Date)
        {
            Caption = 'Warranty Ending Date (Parts)';

            trigger OnValidate()
            begin
                if "Service Item No." <> '' then begin
                    ServItem.Get("Service Item No.");
                    if "Warranty Ending Date (Parts)" <> ServItem."Warranty Ending Date (Parts)" then
                        Error(Text023, ServItem.TableCaption);
                end;
            end;
        }
        field(21; Warranty; Boolean)
        {
            Caption = 'Warranty';

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateWarranty(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Service Item No." = '' then begin
                    GetServHeader;
                    if Warranty then begin
                        if ConfirmManagement.GetResponseOrDefault(Text024, true) then begin
                            Validate("Warranty Starting Date (Parts)", ServHeader."Order Date");
                            Validate("Warranty Starting Date (Labor)", ServHeader."Order Date");
                            Warranty := true;
                        end else
                            Warranty := false;
                    end else begin
                        if ConfirmManagement.GetResponseOrDefault(Text025, true) then begin
                            Validate("Warranty Starting Date (Parts)", 0D);
                            Validate("Warranty Starting Date (Labor)", 0D);
                            Warranty := false;
                        end else
                            Warranty := true;
                    end;
                    if ServItemLine.Get("Document Type", "Document No.", "Line No.") then
                        Modify;
                    CheckWarranty(ServHeader."Order Date");
                end else
                    Error(Text023, ServItem.TableCaption);
            end;
        }
        field(22; "Warranty % (Parts)"; Decimal)
        {
            Caption = 'Warranty % (Parts)';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateWarrantyParts(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Service Item No." <> '' then
                    Error(Text023, ServItem.TableCaption);

                if ("Service Item No." = '') and ("Warranty % (Parts)" <> xRec."Warranty % (Parts)") then begin
                    ServLine.Reset();
                    ServLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.", Type);
                    ServLine.SetRange("Document Type", "Document Type");
                    ServLine.SetRange("Document No.", "Document No.");
                    ServLine.SetRange("Service Item Line No.", "Line No.");
                    ServLine.SetRange(Type, ServLine.Type::Item);
                    if ServLine.Find('-') then
                        repeat
                            ServLine.Validate("Warranty Disc. %", "Warranty % (Parts)");
                            ServLine.Modify();
                        until ServLine.Next = 0;
                end;
            end;
        }
        field(23; "Warranty % (Labor)"; Decimal)
        {
            Caption = 'Warranty % (Labor)';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateWarrantyLabor(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Service Item No." <> '' then
                    Error(Text023, ServItem.TableCaption);

                if ("Service Item No." = '') and ("Warranty % (Labor)" <> xRec."Warranty % (Labor)") then begin
                    ServLine.Reset();
                    ServLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.", Type);
                    ServLine.SetRange("Document Type", "Document Type");
                    ServLine.SetRange("Document No.", "Document No.");
                    ServLine.SetRange("Service Item Line No.", "Line No.");
                    ServLine.SetRange(Type, ServLine.Type::Resource);
                    if ServLine.Find('-') then
                        repeat
                            ServLine.Validate("Warranty Disc. %", "Warranty % (Labor)");
                            ServLine.Modify();
                        until ServLine.Next = 0;
                end;
            end;
        }
        field(24; "Warranty Starting Date (Labor)"; Date)
        {
            Caption = 'Warranty Starting Date (Labor)';

            trigger OnValidate()
            begin
                if "Service Item No." <> '' then begin
                    ServItem.Get("Service Item No.");
                    if "Warranty Starting Date (Labor)" <> ServItem."Warranty Starting Date (Labor)" then
                        Error(Text023, ServItem.TableCaption);
                end;

                if "Warranty Starting Date (Labor)" <> 0D then begin
                    ServMgtSetup.Get();
                    "Warranty Ending Date (Labor)" := CalcDate(ServMgtSetup."Default Warranty Duration", "Warranty Starting Date (Labor)");
                    "Warranty % (Parts)" := ServMgtSetup."Warranty Disc. % (Parts)";
                    "Warranty % (Labor)" := ServMgtSetup."Warranty Disc. % (Labor)";
                end else begin
                    "Warranty Ending Date (Labor)" := 0D;
                    "Warranty % (Labor)" := 0;
                end;
            end;
        }
        field(25; "Warranty Ending Date (Labor)"; Date)
        {
            Caption = 'Warranty Ending Date (Labor)';

            trigger OnValidate()
            begin
                if "Service Item No." <> '' then begin
                    ServItem.Get("Service Item No.");
                    if "Warranty Ending Date (Labor)" <> ServItem."Warranty Ending Date (Labor)" then
                        Error(Text023, ServItem.TableCaption);
                end;
            end;
        }
        field(26; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            TableRelation = "Service Contract Header"."Contract No." WHERE("Contract Type" = CONST(Contract));

            trigger OnLookup()
            var
                ServHeader: Record "Service Header";
                ServContractLine: Record "Service Contract Line";
                ServContractList: Page "Serv. Contr. List (Serv. Item)";
            begin
                ServHeader.Get("Document Type", "Document No.");
                if "Contract No." <> '' then begin
                    ServContractLine.SetRange("Contract Type", ServContractLine."Contract Type"::Contract);
                    ServContractLine.SetRange("Contract No.", "Contract No.");
                    if ServContractLine.FindFirst then
                        ServContractList.SetRecord(ServContractLine);
                    ServContractLine.Reset();
                end;
                ServContractLine.FilterGroup(2);
                ServContractLine.SetRange("Contract Type", ServContractLine."Contract Type"::Contract);
                ServContractLine.SetRange("Customer No.", ServHeader."Customer No.");
                ServContractLine.SetRange("Service Item No.", "Service Item No.");
                ServContractLine.SetRange("Contract Status", ServContractLine."Contract Status"::Signed);
                ServContractLine.SetFilter("Starting Date", '<=%1', ServHeader."Order Date");
                ServContractLine.SetFilter("Contract Expiration Date", '>=%1 | =%2', ServHeader."Order Date", 0D);
                ServContractLine.FilterGroup(0);
                ServContractList.SetTableView(ServContractLine);
                ServContractList.LookupMode(true);
                if ServContractList.RunModal = ACTION::LookupOK then begin
                    ServContractList.GetRecord(ServContractLine);
                    Validate("Contract No.", ServContractLine."Contract No.");
                end;
            end;

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
                IsHandled: Boolean;
            begin
                ServHeader.Get("Document Type", "Document No.");
                if (ServHeader."Contract No." <> '') and
                   ("Contract No." <> ServHeader."Contract No.")
                then
                    Error(Text048, FieldCaption("Contract No."));

                if ("Service Price Group Code" <> '') and ("Contract No." <> '') then
                    Error(Text033);

                ServLine.Reset();
                ServLine.SetRange("Document Type", "Document Type");
                ServLine.SetRange("Document No.", "Document No.");
                if "Line No." <> 0 then begin
                    ServLine.SetRange("Service Item Line No.", "Line No.");
                    ServLine.SetFilter("Quantity Invoiced", '>0');
                    if ServLine.Find('-') then
                        Error(Text053);
                end;

                if "Contract No." <> '' then begin
                    ServContractLine.Reset();
                    ServContractLine.SetRange("Contract Type", ServContractLine."Contract Type"::Contract);
                    ServContractLine.SetRange("Contract No.", "Contract No.");
                    ServContractLine.SetRange("Service Item No.", "Service Item No.");
                    if not ServContractLine.FindFirst then
                        Error(Text049, "Contract No.", "Service Item No.");
                    if ServContractLine."Customer No." <> ServHeader."Customer No." then
                        Error(Text051, "Contract No.");
                    if ServContractLine."Contract Status" <> ServContractLine."Contract Status"::Signed then
                        Error(Text052, "Contract No.");
                    ServHeader.TestField("Order Date");
                    IsHandled := false;
                    OnValidateContractNoOnBeforeValidateServicePeriod(Rec, xRec, CurrFieldNo, IsHandled);
                    if not IsHandled then
                        ServContractLine.ValidateServicePeriod(ServHeader."Order Date");
                    "Contract Line No." := ServContractLine."Line No.";
                end else
                    "Contract Line No." := 0;
                ServLine.SetRange("Quantity Invoiced", 0);

                if ServLine.Find('-') and ("Line No." <> 0) then
                    if ConfirmManagement.GetResponseOrDefault(Text054, true) then begin
                        Modify(true);
                        RecreateServLines(ServLine);
                    end else
                        "Contract No." := xRec."Contract No.";
                UpdateResponseTimeHours;
            end;
        }
        field(27; "Location of Service Item"; Text[30])
        {
            CalcFormula = Lookup ("Service Item"."Location of Service Item" WHERE("No." = FIELD("Service Item No.")));
            Caption = 'Location of Service Item';
            Editable = false;
            FieldClass = FlowField;
        }
        field(28; "Loaner No."; Code[20])
        {
            Caption = 'Loaner No.';
            TableRelation = Loaner."No.";

            trigger OnValidate()
            var
                LoanerEntry: Record "Loaner Entry";
            begin
                if ("Loaner No." = '') and (xRec."Loaner No." <> '') then begin
                    Loaner.Get(xRec."Loaner No.");
                    LoanerEntry.SetRange("Document Type", "Document Type" + 1);
                    LoanerEntry.SetRange("Document No.", "Document No.");
                    LoanerEntry.SetRange("Loaner No.", xRec."Loaner No.");
                    LoanerEntry.SetRange(Lent, true);
                    if not LoanerEntry.IsEmpty then
                        Error(
                          Text026,
                          FieldCaption("Loaner No."))
                end;

                if "Loaner No." <> xRec."Loaner No." then begin
                    LoanerEntry.Reset();
                    LoanerEntry.SetRange("Document Type", "Document Type" + 1);
                    LoanerEntry.SetRange("Document No.", "Document No.");
                    LoanerEntry.SetRange("Loaner No.", xRec."Loaner No.");
                    LoanerEntry.SetRange(Lent, true);
                    if not LoanerEntry.IsEmpty then begin
                        GetServHeader;
                        Error(
                          Text028,
                          FieldCaption("Loaner No."), Format(ServHeader."Document Type"),
                          ServHeader.FieldCaption("No."), ServHeader."No.");
                    end;
                    CheckIfLoanerOnServOrder;
                    if "Line No." <> 0 then
                        LendLoanerWithConfirmation;
                end;
            end;
        }
        field(29; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(30; "Vendor Item No."; Text[50])
        {
            Caption = 'Vendor Item No.';
        }
        field(31; "Fault Reason Code"; Code[10])
        {
            Caption = 'Fault Reason Code';
            TableRelation = "Fault Reason Code";

            trigger OnValidate()
            var
                FaultReasonCode: Record "Fault Reason Code";
                ConfirmManagement: Codeunit "Confirm Management";
                RecR: RecordRef;
                TypeR: FieldRef;
                TypeStr: Text[50];
            begin
                ServLine.Reset();
                ServLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.");
                ServLine.SetRange("Document Type", "Document Type");
                ServLine.SetRange("Document No.", "Document No.");
                ServLine.SetRange("Service Item Line No.", "Line No.");
                if FaultReasonCode.Get("Fault Reason Code") then begin
                    RecR.GetTable(ServLine);
                    TypeR := RecR.FieldIndex(ServLine.FieldNo(Type));
                    TypeStr := TypeR.OptionCaption;
                    if FaultReasonCode."Exclude Warranty Discount" then begin
                        ServLine.SetFilter(Type, '%1|%2', ServLine.Type::Cost, ServLine.Type::"G/L Account");
                        if ServLine.Find('-') then
                            if not ConfirmManagement.GetResponseOrDefault(
                                 StrSubstNo(
                                   Text056,
                                   TableCaption,
                                   FieldCaption("Document No."), "Document No.",
                                   FieldCaption("Line No."), "Line No.",
                                   ServLine.FieldCaption(Type),
                                   SelectStr(ServLine.Type::"G/L Account" + 1, TypeStr),
                                   SelectStr(ServLine.Type::Cost + 1, TypeStr),
                                   FaultReasonCode.FieldCaption("Exclude Warranty Discount"),
                                   FaultReasonCode.TableCaption, FaultReasonCode.Code),
                                 true)
                            then
                                Error('');
                        ServLine.SetRange(Type, ServLine.Type::Item, ServLine.Type::Resource);
                    end else
                        ServLine.SetRange(Type, ServLine.Type::Item, ServLine.Type::"G/L Account");
                end;
                if ServLine.Find('-') then
                    repeat
                        ServLine.Validate("Fault Reason Code", "Fault Reason Code");
                        ServLine.Modify();
                    until ServLine.Next = 0;
            end;
        }
        field(32; "Service Price Group Code"; Code[10])
        {
            Caption = 'Service Price Group Code';
            TableRelation = "Service Price Group";

            trigger OnValidate()
            var
                ServPriceGrSetup: Record "Serv. Price Group Setup";
                ServPriceMgmt: Codeunit "Service Price Management";
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                GetServHeader;
                if ("Service Price Group Code" <> '') and
                   (("Contract No." <> '') or (ServHeader."Contract No." <> ''))
                then
                    Error(Text033);

                ServLine.Reset();
                ServLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.", Type);
                ServLine.SetRange("Document Type", "Document Type");
                ServLine.SetRange("Document No.", "Document No.");
                ServLine.SetRange("Service Item Line No.", "Line No.");

                if "Service Price Group Code" <> xRec."Service Price Group Code" then begin
                    ServLine.SetFilter("Quantity Invoiced", '>0');
                    if ServLine.Find('-') then
                        Error(Text037, FieldCaption("Service Price Group Code"));
                end;

                if CurrFieldNo = FieldNo("Service Price Group Code") then
                    if CheckServLineExist then begin
                        ServLine.SetRange("Price Adjmt. Status", ServLine."Price Adjmt. Status"::Adjusted);
                        if ServLine.Find('-') then begin
                            if not ConfirmManagement.GetResponseOrDefault(
                                 StrSubstNo(Text038, ServLine.TableCaption), true)
                            then
                                Error(Text039);
                            ServPriceMgmt.ResetAdjustedLines(ServLine);
                        end;
                        ServLine.SetRange("Price Adjmt. Status");
                    end;

                if "Service Price Group Code" <> '' then begin
                    ServPriceMgmt.GetServPriceGrSetup(ServPriceGrSetup, ServHeader, Rec);
                    "Serv. Price Adjmt. Gr. Code" := ServPriceGrSetup."Serv. Price Adjmt. Gr. Code";
                    "Adjustment Type" := ServPriceGrSetup."Adjustment Type";
                    "Base Amount to Adjust" := ServPriceGrSetup.Amount;
                end else begin
                    "Serv. Price Adjmt. Gr. Code" := '';
                    Clear("Adjustment Type");
                    "Base Amount to Adjust" := 0;
                end;

                if ServLine.Find('-') then
                    repeat
                        ServLine."Service Price Group Code" := "Service Price Group Code";
                        ServLine."Serv. Price Adjmt. Gr. Code" := "Serv. Price Adjmt. Gr. Code";
                        ServLine.Modify();
                    until ServLine.Next = 0;
            end;
        }
        field(33; "Fault Area Code"; Code[10])
        {
            Caption = 'Fault Area Code';
            TableRelation = "Fault Area";

            trigger OnValidate()
            var
                ServPriceMgmt: Codeunit "Service Price Management";
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if (CurrFieldNo = FieldNo("Fault Area Code")) and
                   ("Fault Area Code" <> xRec."Fault Area Code")
                then begin
                    if CheckServLineExist and ("Service Price Group Code" <> '') then begin
                        ServLine.Reset();
                        ServLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.");
                        ServLine.SetRange("Document Type", "Document Type");
                        ServLine.SetRange("Document No.", "Document No.");
                        ServLine.SetRange("Service Item Line No.", "Line No.");
                        ServLine.SetRange("Price Adjmt. Status", ServLine."Price Adjmt. Status"::Adjusted);
                        if ServLine.Find('-') then begin
                            if not ConfirmManagement.GetResponseOrDefault(
                                 StrSubstNo(Text038, ServLine.TableCaption), true)
                            then
                                Error(Text039);
                            ServPriceMgmt.ResetAdjustedLines(ServLine);
                        end;
                    end;
                    Validate("Service Price Group Code");
                    "Fault Code" := '';
                end;
            end;
        }
        field(34; "Symptom Code"; Code[10])
        {
            Caption = 'Symptom Code';
            TableRelation = "Symptom Code";

            trigger OnValidate()
            begin
                if "Symptom Code" <> xRec."Symptom Code" then
                    "Fault Code" := '';
            end;
        }
        field(35; "Fault Code"; Code[10])
        {
            Caption = 'Fault Code';
            TableRelation = "Fault Code".Code WHERE("Fault Area Code" = FIELD("Fault Area Code"),
                                                     "Symptom Code" = FIELD("Symptom Code"));
        }
        field(36; "Resolution Code"; Code[10])
        {
            Caption = 'Resolution Code';
            TableRelation = "Resolution Code";
        }
        field(37; "Fault Comment"; Boolean)
        {
            CalcFormula = Exist ("Service Comment Line" WHERE("Table Name" = CONST("Service Header"),
                                                              "Table Subtype" = FIELD("Document Type"),
                                                              "No." = FIELD("Document No."),
                                                              Type = CONST(Fault),
                                                              "Table Line No." = FIELD("Line No.")));
            Caption = 'Fault Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(38; "Resolution Comment"; Boolean)
        {
            CalcFormula = Exist ("Service Comment Line" WHERE("Table Name" = CONST("Service Header"),
                                                              "Table Subtype" = FIELD("Document Type"),
                                                              "No." = FIELD("Document No."),
                                                              Type = CONST(Resolution),
                                                              "Table Line No." = FIELD("Line No.")));
            Caption = 'Resolution Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(40; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));

            trigger OnValidate()
            begin
                if "Service Item No." <> '' then
                    Error(
                      Text016,
                      FieldCaption("Variant Code"), FieldCaption("Service Item No."))
            end;
        }
        field(41; "Service Item Loaner Comment"; Boolean)
        {
            CalcFormula = Exist ("Service Comment Line" WHERE("Table Name" = CONST("Service Header"),
                                                              "Table Subtype" = FIELD("Document Type"),
                                                              "No." = FIELD("Document No."),
                                                              Type = CONST("Service Item Loaner"),
                                                              "Table Line No." = FIELD("Line No.")));
            Caption = 'Service Item Loaner Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(42; "Actual Response Time (Hours)"; Decimal)
        {
            Caption = 'Actual Response Time (Hours)';
            DecimalPlaces = 0 : 5;
        }
        field(43; "Document Type"; Option)
        {
            Caption = 'Document Type';
            Editable = false;
            OptionCaption = 'Quote,Order';
            OptionMembers = Quote,"Order";
        }
        field(44; "Serv. Price Adjmt. Gr. Code"; Code[10])
        {
            Caption = 'Serv. Price Adjmt. Gr. Code';
            Editable = false;
            TableRelation = "Service Price Adjustment Group";
        }
        field(45; "Adjustment Type"; Option)
        {
            Caption = 'Adjustment Type';
            Editable = false;
            OptionCaption = 'Fixed,Maximum,Minimum';
            OptionMembers = "Fixed",Maximum,Minimum;
        }
        field(46; "Base Amount to Adjust"; Decimal)
        {
            Caption = 'Base Amount to Adjust';
            Editable = false;
        }
        field(60; "No. of Active/Finished Allocs"; Integer)
        {
            CalcFormula = Count ("Service Order Allocation" WHERE("Document Type" = FIELD("Document Type"),
                                                                  "Document No." = FIELD("Document No."),
                                                                  "Service Item Line No." = FIELD("Line No."),
                                                                  "Resource No." = FIELD("Resource Filter"),
                                                                  "Resource Group No." = FIELD("Resource Group Filter"),
                                                                  "Allocation Date" = FIELD("Allocation Date Filter"),
                                                                  Status = FILTER(Active | Finished)));
            Caption = 'No. of Active/Finished Allocs';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "No. of Allocations"; Integer)
        {
            CalcFormula = Count ("Service Order Allocation" WHERE(Status = FIELD("Allocation Status Filter"),
                                                                  "Resource No." = FIELD("Resource Filter"),
                                                                  "Resource Group No." = FIELD("Resource Group Filter"),
                                                                  "Document Type" = FIELD("Document Type"),
                                                                  "Document No." = FIELD("Document No."),
                                                                  "Service Item Line No." = FIELD("Line No.")));
            Caption = 'No. of Allocations';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62; "No. of Previous Services"; Integer)
        {
            CalcFormula = Count ("Service Shipment Item Line" WHERE("Item No." = FIELD("Item No."),
                                                                    "Serial No." = FIELD("Serial No.")));
            Caption = 'No. of Previous Services';
            Editable = false;
            FieldClass = FlowField;
        }
        field(63; "Contract Line No."; Integer)
        {
            Caption = 'Contract Line No.';
            TableRelation = "Service Contract Line"."Line No." WHERE("Contract Type" = CONST(Contract),
                                                                      "Contract No." = FIELD("Contract No."));
        }
        field(64; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            Editable = false;
            TableRelation = "Ship-to Address".Code WHERE("Customer No." = FIELD("Customer No."));
        }
        field(65; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            Editable = false;
            TableRelation = Customer."No.";
        }
        field(91; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(92; "Resource Filter"; Code[20])
        {
            Caption = 'Resource Filter';
            FieldClass = FlowFilter;
            TableRelation = Resource;
        }
        field(93; "Allocation Date Filter"; Date)
        {
            Caption = 'Allocation Date Filter';
            FieldClass = FlowFilter;
        }
        field(94; "Repair Status Code Filter"; Code[10])
        {
            Caption = 'Repair Status Code Filter';
            FieldClass = FlowFilter;
            TableRelation = "Repair Status".Code;
        }
        field(96; "Allocation Status Filter"; Option)
        {
            Caption = 'Allocation Status Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Nonactive,Active,Finished,Canceled,Reallocation Needed';
            OptionMembers = Nonactive,Active,Finished,Canceled,"Reallocation Needed";
        }
        field(97; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            Editable = false;
            TableRelation = "Responsibility Center";
        }
        field(98; "Service Order Filter"; Code[20])
        {
            Caption = 'Service Order Filter';
            FieldClass = FlowFilter;
            TableRelation = "Service Header"."No.";
        }
        field(99; "Resource Group Filter"; Code[20])
        {
            Caption = 'Resource Group Filter';
            FieldClass = FlowFilter;
            TableRelation = "Resource Group";
        }
        field(100; "Shortcut Dimension 1 Code"; Code[20])
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
        field(101; "Shortcut Dimension 2 Code"; Code[20])
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
        field(130; "Release Status"; Option)
        {
            Caption = 'Release Status';
            OptionCaption = 'Open,Released to Ship';
            OptionMembers = Open,"Released to Ship";
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
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "Line No.", "Document Type")
        {
        }
        key(Key3; "Document Type", "Document No.", "Service Item No.", "Contract No.", "Contract Line No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key4; "Service Item No.")
        {
        }
        key(Key5; "Document Type", "Document No.", "Response Date", "Response Time")
        {
        }
        key(Key6; "Response Date", "Response Time", Priority)
        {
        }
        key(Key7; "Loaner No.")
        {
        }
        key(Key8; "Document Type", "Document No.", "Starting Date", "Starting Time")
        {
            MaintainSQLIndex = false;
        }
        key(Key9; "Document Type", "Document No.", "Finishing Date", "Finishing Time")
        {
            MaintainSQLIndex = false;
        }
        key(Key10; "Fault Reason Code")
        {
        }
        key(Key11; "Contract No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Service Item No.", Description, "Serial No.")
        {
        }
    }

    trigger OnDelete()
    var
        LoanerEntry: Record "Loaner Entry";
    begin
        if "Loaner No." <> '' then begin
            Loaner.Get("Loaner No.");
            LoanerEntry.SetRange("Document Type", "Document Type" + 1);
            LoanerEntry.SetRange("Document No.", "Document No.");
            LoanerEntry.SetRange("Loaner No.", "Loaner No.");
            LoanerEntry.SetRange(Lent, true);
            if not LoanerEntry.IsEmpty then
                Error(
                  Text006,
                  TableCaption, "Document No.", "Line No.", FieldCaption("Loaner No."), "Loaner No.");
            LoanerEntry.SetRange(Lent, true);
            LoanerEntry.DeleteAll();
        end;

        ServLine.Reset();
        ServLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.");
        ServLine.SetRange("Document Type", "Document Type");
        ServLine.SetRange("Document No.", "Document No.");
        ServLine.SetRange("Service Item Line No.", "Line No.");
        if ServLine.Find('-') then
            Error(
              Text008,
              TableCaption, "Document No.", "Line No.", ServLine.TableCaption);

        ServOrderAlloc.Reset();
        ServOrderAlloc.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.");
        ServOrderAlloc.SetRange("Document Type", "Document Type");
        ServOrderAlloc.SetRange("Document No.", "Document No.");
        ServOrderAlloc.SetRange("Service Item Line No.", "Line No.");
        ServOrderAlloc.SetFilter(Status, '%1|%2', ServOrderAlloc.Status::Active, ServOrderAlloc.Status::Finished);
        if ServOrderAlloc.Find('-') then
            Error(
              Text008,
              TableCaption, "Document No.", "Line No.", ServOrderAlloc.TableCaption);
        ServOrderAlloc.SetRange(Status);
        ServOrderAlloc.DeleteAll();

        ServCommentLine.Reset();
        ServCommentLine.SetRange("Table Name", ServCommentLine."Table Name"::"Service Header");
        ServCommentLine.SetRange("Table Subtype", "Document Type");
        ServCommentLine.SetRange("No.", "Document No.");
        ServCommentLine.SetRange("Table Line No.", "Line No.");
        ServCommentLine.DeleteAll();

        Clear(ServLogMgt);
        ServLogMgt.ServItemOffServOrder(Rec);

        ServOrderMgt.UpdateResponseDateTime(Rec, true);
        UpdateStartFinishDateTime("Document Type", "Document No.", "Line No.", CalcDate('<CY+1D-1Y>', WorkDate), 0T, 0D, 0T, true);
        ServOrderMgt.UpdatePriority(Rec, true);
    end;

    trigger OnInsert()
    begin
        ServMgtSetup.Get();
        ServItemLine.Reset();
        ServItemLine.SetRange("Document Type", "Document Type");
        ServItemLine.SetRange("Document No.", "Document No.");
        FirstServItemLine := not ServItemLine.Find('-');
        if ServMgtSetup."One Service Item Line/Order" then
            if not FirstServItemLine then
                Error(Text000, ServMgtSetup.TableCaption, ServItemLine.TableCaption, ServHeader.TableCaption);

        GetServHeader;
        if ServHeader."Customer No." = '' then begin
            if (ServHeader.Name <> '') and (ServHeader.Address <> '') and (ServHeader.City <> '') then
                Error(
                  Text001,
                  TableCaption, ServHeader.FieldCaption("Customer No."), ServHeader.TableCaption, ServHeader."No.");
            Error(
              Text002,
              TableCaption, ServHeader.FieldCaption("Customer No."), ServHeader.TableCaption, ServHeader."No.");
        end;

        "Responsibility Center" := ServHeader."Responsibility Center";
        "Customer No." := ServHeader."Customer No.";
        if ServHeader."Contract No." <> '' then
            if "Service Item No." = '' then
                "Contract No." := ServHeader."Contract No."
            else begin
                ServContractLine.Reset();
                ServContractLine.SetRange("Contract Type", ServContractLine."Contract Type"::Contract);
                ServContractLine.SetRange("Contract No.", ServHeader."Contract No.");
                ServContractLine.SetRange("Service Item No.", "Service Item No.");
                ServContractLine.SetRange("Contract Status", ServContractLine."Contract Status"::Signed);
                ServContractLine.SetFilter("Starting Date", '<=%1', ServHeader."Order Date");
                ServContractLine.SetFilter("Contract Expiration Date", '>%1 | =%2', ServHeader."Order Date", 0D);
                if ServContractLine.FindFirst then
                    "Contract No." := ServHeader."Contract No.";
            end;
        if ("Contract No." <> '') and ("Service Price Group Code" <> '') then
            Validate("Service Price Group Code", '');

        ServOrderAllocMgt.CreateAllocationEntry(
          "Document Type", "Document No.", "Line No.", "Service Item No.", "Serial No.");

        Clear(ServLogMgt);
        ServLogMgt.ServItemToServOrder(Rec);

        if (ServHeader."Quote No." = '') and ("Response Time (Hours)" = 0) then
            UpdateResponseTimeHours;
        ServOrderMgt.UpdateResponseDateTime(Rec, false);
        ServOrderMgt.UpdatePriority(Rec, false);

        if "Line No." = 0 then
            LendLoanerWithConfirmation;

        if "Service Item No." = '' then
            "Ship-to Code" := ServHeader."Ship-to Code";
        if FirstServItemLine and
           ("Document Type" = "Document Type"::Order)
        then begin
            Clear(SegManagement);
            if ServHeader."Bill-to Contact No." <> '' then
                SegManagement.LogDocument(
                  9, "Document No.", 0, 0, DATABASE::Contact, ServHeader."Bill-to Contact No.",
                  ServHeader."Salesperson Code", '', ServHeader.Description, '')
            else
                SegManagement.LogDocument(
                  9, "Document No.", 0, 0, DATABASE::Customer, ServHeader."Bill-to Customer No.",
                  ServHeader."Salesperson Code", '', ServHeader.Description, '');
        end;
    end;

    trigger OnModify()
    begin
        if UseServItemLineAsxRec then begin
            xRec := ServItemLine;
            UseServItemLineAsxRec := false;
        end;

        OnBeforeOnModify(Rec, xRec);

        if ("Service Item No." <> xRec."Service Item No.") or ("Serial No." <> xRec."Serial No.") then begin
            ServLine.Reset();
            ServLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.");
            ServLine.SetRange("Document Type", "Document Type");
            ServLine.SetRange("Document No.", "Document No.");
            ServLine.SetRange("Service Item Line No.", "Line No.");
            if ServLine.Find('-') then
                repeat
                    ServLine."Service Item No." := "Service Item No.";
                    ServLine."Service Item Serial No." := "Serial No.";
                    ServLine.Modify(true);
                until ServLine.Next = 0;

            ServOrderAlloc.Reset();
            ServOrderAlloc.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.");
            ServOrderAlloc.SetRange("Document Type", "Document Type");
            ServOrderAlloc.SetRange("Document No.", "Document No.");
            ServOrderAlloc.SetRange("Service Item Line No.", "Line No.");
            if ServOrderAlloc.Find('-') then
                repeat
                    ServOrderAlloc."Service Item No." := "Service Item No.";
                    ServOrderAlloc."Service Item Serial No." := "Serial No.";
                    ServOrderAlloc.Modify(true);
                until ServOrderAlloc.Next = 0;
        end;

        if (("Fault Area Code" <> xRec."Fault Area Code") or
            ("Symptom Code" <> xRec."Symptom Code") or
            ("Fault Code" <> xRec."Fault Code") or
            ("Resolution Code" <> xRec."Resolution Code")) and
           CheckServLineExist
        then
            Message(
              Text003,
              TableCaption);
        if "Service Item No." <> xRec."Service Item No." then begin
            Clear(ServLogMgt);
            ServLogMgt.ServItemOffServOrder(xRec);
            ServLogMgt.ServItemToServOrder(Rec);
        end;

        ServOrderMgt.UpdateResponseDateTime(Rec, false);
        ServOrderMgt.UpdatePriority(Rec, false);
        UpdateServiceOrderChangeLog(xRec);
    end;

    trigger OnRename()
    begin
        Error(Text010, TableCaption);
    end;

    var
        Text000: Label 'The %1 allows only one %2 in each %3.';
        Text001: Label 'You cannot insert %1, because %2 is missing in %3 %4.\\You can create a customer by clicking Functions,Create Customer.';
        Text002: Label 'You cannot insert %1, because %2 is missing in %3 %4.';
        Text003: Label 'You have changed one of the fault reporting codes on the %1, but it has not been changed on the existing service lines. You must update the existing service lines manually.';
        Text006: Label 'You cannot delete %1 %2,%3, because %4 %5 has not been received.';
        Text008: Label 'You cannot delete %1 %2,%3, because %4 is attached to it.';
        Text010: Label 'You cannot rename a %1.';
        Text011: Label 'You cannot change the %1 on the %2, because %3 is attached to it.';
        Text012: Label '%1 %2 does not belong to %3 %4.';
        Text016: Label 'You cannot change the %1 field because it is linked to the %2 specified on the line.';
        Text018: Label 'The %1 cannot be greater than the %2 %3.';
        Text019: Label 'The %1 cannot be earlier than the %2.';
        Text020: Label 'The %1 cannot be greater than the %2.';
        Text022: Label 'The %1 cannot be earlier than the %2 %3.';
        Text023: Label 'You cannot change the warranty information because %1 is selected.';
        Text024: Label 'Do you want to activate a warranty for this service item line?';
        Text025: Label 'Do you want to deactivate the warranty for this service item line?';
        Text026: Label 'You cannot reset the %1 field.\You can receive it by clicking Functions, Receive Loaner.';
        Text028: Label 'You cannot change the %1, because it has been lent in connection with %2 %3 %4.\\You can receive it by clicking Functions, Receive Loaner.', Comment = '1%=FIELDCAPTION("Loaner No."); 2%=FORMAT(ServHeader."Document Type"); 3%=ServHeader.FIELDCAPTION("No."); 4%=ServHeader."No.");';
        Text029: Label 'Do you want to lend %1 %2?';
        Text030: Label '%1 %2 has already been lent within %3 %4 %5.', Comment = '1%=TempServItemLine.FIELDCAPTION("Loaner No."); 2%=TempServItemLine."Loaner No."; 3%=FORMAT(ServHeader."Document Type"); 4%=ServHeader.FIELDCAPTION("No."); 5%=ServHeader."No.");';
        ServMgtSetup: Record "Service Mgt. Setup";
        ServOrderAlloc: Record "Service Order Allocation";
        ServItem: Record "Service Item";
        ServContract: Record "Service Contract Header";
        ServLine: Record "Service Line";
        ServItemLine: Record "Service Item Line";
        ServHour: Record "Service Hour";
        ServHour2: Record "Service Hour";
        ServHeader: Record "Service Header";
        ServHeader2: Record "Service Header";
        ServHeader3: Record "Service Header";
        ServCommentLine: Record "Service Comment Line";
        ServItemGr: Record "Service Item Group";
        RepairStatus: Record "Repair Status";
        RepairStatus2: Record "Repair Status";
        Loaner: Record Loaner;
        ServContractLine: Record "Service Contract Line";
        Item: Record Item;
        ServLogMgt: Codeunit ServLogManagement;
        ServOrderAllocMgt: Codeunit ServAllocationManagement;
        ServOrderMgt: Codeunit ServOrderManagement;
        SegManagement: Codeunit SegManagement;
        ServLoanerMgt: Codeunit ServLoanerManagement;
        DimMgt: Codeunit DimensionManagement;
        NoOfRec: Integer;
        TempDay: Integer;
        FirstServItemLine: Boolean;
        TempDate: Date;
        Text033: Label 'A service item line cannot belong to a service contract and to a service price group at the same time.';
        Text035: Label 'The %1 %2 cannot be used in service orders.';
        Text036: Label 'The %1 %2 cannot be used in service quotes.';
        RepairStatusPriority: Integer;
        UseLineNo: Integer;
        Text037: Label 'It is not possible to select %1 because some linked service lines have been posted.';
        LoanerLent: Boolean;
        ServContractExist: Boolean;
        Text038: Label 'Price adjustment on each existing %1 will be cancelled. Continue?';
        Text039: Label 'The update has been interrupted to respect the warning.';
        HideDialogBox: Boolean;
        Text040: Label 'The selected %1 has a different %2 for this %3.\\Do you want to continue?';
        Text041: Label 'You must specify %1 on %2 in the %3 window for the %4 %5.', Comment = '1%=ServHour.FIELDCAPTION("Starting Time"); 2%=ServHour.Day; 3%=Text058=''Service Hours''; %4=ServHour.FIELDCAPTION("Service Contract No.");%5="Contract No.");';
        Text042: Label 'You must specify %1 on %2 in the %3 window.';
        Text043: Label 'You must specify %1 on %2, %3 %4 in the %5 window for the %6 %7.', Comment = '3%=FIELDCAPTION("Starting Date"); 4%=ServHour."Starting Date"; 6%=ServHour.FIELDCAPTION("Service Contract No."); 7%="Contract No.");';
        Text044: Label 'You must specify %1 on %2, %3 %4 in the %5 window.', Comment = '1%=ServHour.FIELDCAPTION("Starting Time"); 2%=ServHour.Day; 3%=ServHour.FIELDCAPTION("Starting Date"); 4%=ServHour."Starting Date"; 5%=Text057=''Default Service Hours'';';
        Text045: Label 'The %1 for this %2 occurs in more than 1 year. Please verify the setting for service hours and the %3 for the %4.';
        Text047: Label 'Service item %1 is included in more than one contract.\\Do you want to assign a contract number to the service order line?';
        Text048: Label 'You cannot change the %1 because it has already been set on the header.';
        Text049: Label 'Contract %1 does not include service item %2.';
        Text050: Label 'Service contract %1 specified on the service order header does not include service item %2.';
        Text051: Label 'You cannot select contract %1 because it is owned by another customer.';
        Text052: Label 'Contract %1 is not signed.';
        Text053: Label 'You cannot change the contract number because some of the service lines have already been posted.';
        Text054: Label 'If you change the contract number, the existing service lines for this order line will be re-created.\Do you want to continue?';
        UseServItemLineAsxRec: Boolean;
        SkipResponseTimeHrsUpdate: Boolean;
        Text055: Label 'You cannot change the %1 because %2 %3 has not been received.', Comment = '2%=FIELDCAPTION("Loaner No."); 3%="Loaner No.";';
        Text056: Label 'One or more service lines of %6 %7 and/or %8 exist for %1, %2 %3, %4 %5. There is a check mark in the %9 field of %10 %11, therefore %10 %11 cannot be applied to service line of %6 %7 and/or %8.\\ Do you want to apply it for other service lines?';
        Text057: Label 'Default Service Hours';
        Text058: Label 'Service Hours';
        Text059: Label 'Default warranty duration is negative. The warranty cannot be activated.';
        Text060: Label 'You may have changed a dimension.\\Do you want to update the lines?';

    procedure SetUpNewLine()
    begin
        if ServHeader.Get("Document Type", "Document No.") then begin
            "Document Type" := ServHeader."Document Type";
            RepairStatus.Reset();
            RepairStatus.Initial := true;
            "Repair Status Code" := RepairStatus.ReturnStatusCode(RepairStatus);
        end;

        OnAfterSetUpNewLine(Rec);
    end;

    procedure SetServHeader(var NewServHeader: Record "Service Header")
    begin
        ServHeader := NewServHeader;
    end;

    local procedure GetServHeader()
    begin
        if ServHeader."No." <> "Document No." then
            ServHeader.Get("Document Type", "Document No.");
    end;

    procedure CheckWarranty(Date: Date)
    var
        WarrantyLabor: Boolean;
        WarrantyParts: Boolean;
        IsHandled: Boolean;
    begin
        if "Warranty Starting Date (Parts)" > "Warranty Ending Date (Parts)" then begin
            Validate("Warranty Starting Date (Parts)", 0D);
            Validate("Warranty Starting Date (Labor)", 0D);
            Error(Text059);
        end;

        if ((Date >= "Warranty Starting Date (Parts)") and (Date <= "Warranty Ending Date (Parts)")) or
           ((Date >= "Warranty Starting Date (Labor)") and (Date <= "Warranty Ending Date (Labor)"))
        then
            Warranty := true
        else
            Warranty := false;

        IsHandled := false;
        OnCheckWarrantyOnAfterSetWarranty(Rec, IsHandled);
        if IsHandled then
            exit;

        WarrantyParts := (Date >= "Warranty Starting Date (Parts)") and (Date <= "Warranty Ending Date (Parts)");
        WarrantyLabor := (Date >= "Warranty Starting Date (Labor)") and (Date <= "Warranty Ending Date (Labor)");

        ServLine.Reset();
        ServLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.");
        ServLine.SetRange("Document Type", "Document Type");
        ServLine.SetRange("Document No.", "Document No.");
        ServLine.SetRange("Service Item Line No.", "Line No.");
        ServLine.SetFilter("Quantity Invoiced", '=0');
        if ServLine.Find('-') then
            repeat
                if ServLine.Type = ServLine.Type::Item then begin
                    if ServLine."Warranty Disc. %" <> "Warranty % (Parts)" then
                        ServLine.Validate("Warranty Disc. %", "Warranty % (Parts)");
                    if WarrantyParts then begin
                        ServLine.Warranty := WarrantyParts;
                        ServLine.Validate("Fault Reason Code");
                        ServLine.Validate(Warranty);
                    end else begin
                        ServLine.Warranty := false;
                        ServLine."Exclude Warranty" := false;
                    end;
                end;
                if ServLine.Type = ServLine.Type::Resource then begin
                    if ServLine."Warranty Disc. %" <> "Warranty % (Labor)" then
                        ServLine.Validate("Warranty Disc. %", "Warranty % (Labor)");
                    if WarrantyLabor then begin
                        ServLine.Warranty := WarrantyLabor;
                        ServLine.Validate("Fault Reason Code");
                        ServLine.Validate(Warranty);
                    end else begin
                        ServLine.Warranty := false;
                        ServLine."Exclude Warranty" := false;
                    end;
                end;
                ServLine.Modify();
            until ServLine.Next = 0;
    end;

    local procedure CheckIfLoanerOnServOrder()
    var
        ServItemLine: Record "Service Item Line";
    begin
        LoanerLent := false;
        if "Loaner No." <> '' then begin
            ServItemLine.Reset();
            ServItemLine.SetCurrentKey("Loaner No.");
            ServItemLine.SetRange("Loaner No.", "Loaner No.");
            if ServItemLine.Find('-') then
                if (ServItemLine."Document Type" <> "Document Type") or
                   (ServItemLine."Document No." <> "Document No.") or
                   (ServItemLine."Line No." <> "Line No.")
                then
                    LoanerLent := true
                else
                    if ServItemLine.Next <> 0 then
                        LoanerLent := true;

            if LoanerLent then begin
                ServHeader.Get(
                  ServItemLine."Document Type", ServItemLine."Document No.");

                Error(
                  Text030,
                  ServItemLine.FieldCaption("Loaner No."), ServItemLine."Loaner No.",
                  Format(ServHeader."Document Type"), ServHeader.FieldCaption("No."),
                  ServHeader."No.");
            end;
        end;
    end;

    procedure CalculateResponseDateTime(OrderDate: Date; OrderTime: Time)
    var
        CalChange: Record "Customized Calendar Change";
        CalendarMgmt: Codeunit "Calendar Management";
        TotTime: Decimal;
        LastTotTime: Decimal;
        HoursLeft: Decimal;
        HoursOnLastDay: Decimal;
        Holiday: Boolean;
        NewDescription: Text[30];
        ContractServHourExist: Boolean;
        ErrorDate: Date;
        WholeResponseDays: Integer;
        StartingTime: Time;
    begin
        ServMgtSetup.Get();
        ServMgtSetup.TestField("Base Calendar Code");
        CalendarMgmt.SetSource(ServMgtSetup, CalChange);

        ServHour.Reset();
        if "Contract No." <> '' then begin
            if CheckIfServHourExist("Contract No.") then begin
                ContractServHourExist := true;
                ServHour.SetRange("Service Contract Type", ServHour."Service Contract Type"::Contract);
                ServHour.SetRange("Service Contract No.", "Contract No.")
            end else begin
                ServHour.SetRange("Service Contract Type", ServHour."Service Contract Type"::" ");
                ServHour.SetRange("Service Contract No.", '')
            end;
        end else
            ServHour.SetRange("Service Contract No.", '');

        HoursLeft := "Response Time (Hours)";

        if not ServHour.FindFirst then begin
            WholeResponseDays := HoursLeft div 24;
            HoursOnLastDay := HoursLeft - WholeResponseDays * 24;
            if CalendarMgmt.CalcTimeDelta(OrderTime, 000000T) / 3600000 + HoursOnLastDay >= 24 then begin
                WholeResponseDays := WholeResponseDays + 1;
                HoursOnLastDay := HoursOnLastDay - 24;
            end;
            "Response Date" := OrderDate + WholeResponseDays;
            "Response Time" := OrderTime + HoursOnLastDay * 3600000;
            exit;
        end;
        if OrderDate = 0D then
            exit;
        TotTime := 0;
        LastTotTime := 0;
        TempDate := OrderDate;
        ErrorDate := OrderDate + 365;
        HoursLeft := HoursLeft * 3600000;

        repeat
            TempDay := Date2DWY(TempDate, 1) - 1;
            HoursOnLastDay := 0;
            ServHour.SetFilter("Starting Date", '<=%1', TempDate);
            ServHour.SetRange(Day, TempDay);
            if ServHour.FindLast then begin
                if ServHour."Valid on Holidays" then
                    Holiday := false
                else
                    Holiday := CalendarMgmt.IsNonworkingDay(TempDate, CalChange);
                if not Holiday then begin
                    if TempDate = OrderDate then begin
                        if OrderTime < ServHour."Ending Time" then begin
                            if OrderTime >= ServHour."Starting Time" then
                                StartingTime := OrderTime
                            else
                                StartingTime := ServHour."Starting Time";

                            if HoursLeft > CalendarMgmt.CalcTimeDelta(ServHour."Ending Time", StartingTime) then begin
                                TotTime := TotTime + CalendarMgmt.CalcTimeDelta(ServHour."Ending Time", StartingTime);
                                HoursOnLastDay := CalendarMgmt.CalcTimeDelta(ServHour."Ending Time", StartingTime);
                            end else begin
                                TotTime := TotTime + HoursLeft;
                                HoursOnLastDay := HoursLeft;
                            end;
                        end;
                    end else begin
                        if ServHour."Starting Time" = 0T then begin
                            if ("Contract No." <> '') and ContractServHourExist then begin
                                if ServHour."Starting Date" <> 0D then
                                    Error(
                                      Text043,
                                      FieldCaption("Starting Time"),
                                      ServHour.Day,
                                      FieldCaption("Starting Date"),
                                      ServHour."Starting Date",
                                      Text058,
                                      ServHour.FieldCaption("Service Contract No."),
                                      "Contract No.");

                                Error(
                                  Text041,
                                  ServHour.FieldCaption("Starting Time"),
                                  ServHour.Day,
                                  Text058,
                                  ServHour.FieldCaption("Service Contract No."),
                                  "Contract No.");
                            end;
                            if ServHour."Starting Date" <> 0D then
                                Error(
                                  Text044,
                                  ServHour.FieldCaption("Starting Time"),
                                  ServHour.Day,
                                  ServHour.FieldCaption("Starting Date"),
                                  ServHour."Starting Date",
                                  Text057);

                            Error(
                              Text042,
                              FieldCaption("Starting Time"),
                              ServHour.Day,
                              Text057)
                            ;
                        end;

                        if ServHour."Ending Time" = 0T then begin
                            if ("Contract No." <> '') and ContractServHourExist then begin
                                if ServHour."Starting Date" <> 0D then
                                    Error(
                                      Text043,
                                      ServHour.FieldCaption("Ending Time"),
                                      ServHour.Day,
                                      ServHour.FieldCaption("Starting Date"),
                                      ServHour."Starting Date",
                                      Text058,
                                      ServHour.FieldCaption("Service Contract No."),
                                      "Contract No.");

                                Error(
                                  Text041,
                                  ServHour.FieldCaption("Ending Time"),
                                  ServHour.Day,
                                  Text058,
                                  ServHour.FieldCaption("Service Contract No."),
                                  "Contract No.");
                            end;
                            CheckServHourStartingDate(ServHour);
                            Error(
                              Text042,
                              ServHour.FieldCaption("Ending Time"),
                              ServHour.Day,
                              Text057)
                            ;
                        end;

                        if HoursLeft > CalendarMgmt.CalcTimeDelta(ServHour."Ending Time", ServHour."Starting Time") then begin
                            TotTime := TotTime + CalendarMgmt.CalcTimeDelta(ServHour."Ending Time", ServHour."Starting Time");
                            HoursOnLastDay := CalendarMgmt.CalcTimeDelta(ServHour."Ending Time", ServHour."Starting Time");
                        end else begin
                            TotTime := TotTime + HoursLeft;
                            HoursOnLastDay := HoursLeft;
                        end;
                    end;
                    if LastTotTime < TotTime then begin
                        HoursLeft := HoursLeft - (TotTime - LastTotTime);
                        LastTotTime := TotTime;
                    end;
                end;
            end;
            TempDate := TempDate + 1;
        until (HoursLeft <= 0) or (TempDate > ErrorDate);

        CheckTempDateErrorDate(TempDate, ErrorDate, ServItem.FieldCaption("Response Time (Hours)"), ServItem.TableCaption);

        if TotTime > 0 then begin
            "Response Date" := TempDate - 1;
            if ("Response Date" = OrderDate) and (OrderTime > ServHour."Starting Time") then
                "Response Time" := OrderTime + HoursOnLastDay
            else
                "Response Time" := ServHour."Starting Time" + HoursOnLastDay;
        end else begin
            "Response Date" := OrderDate;
            "Response Time" := OrderTime;
        end;
    end;

    local procedure CheckServItemCustomer(ServiceHeader: Record "Service Header"; ServiceItem: Record "Service Item");
    VAR
        IsHandled: Boolean;
    BEGIN
        IsHandled := FALSE;
        OnBeforeCheckServItemCustomer(ServiceHeader, ServiceItem, IsHandled);
        if IsHandled then
            Exit;

        if ServiceHeader."Customer No." <> ServiceItem."Customer No." then
            Error(
              Text012,
              ServiceItem.TableCaption, "Service Item No.", ServiceHeader.FieldCaption("Customer No."), ServiceHeader."Customer No.");
    END;

    procedure CheckServLineExist(): Boolean
    begin
        if "Line No." = 0 then
            exit(false);

        ServLine.Reset();
        ServLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.", Type);
        ServLine.SetRange("Document Type", "Document Type");
        ServLine.SetRange("Document No.", "Document No.");
        ServLine.SetRange("Service Item Line No.", "Line No.");
        exit(ServLine.Find('-'));
    end;

    procedure CheckIfServHourExist(ContractNo: Code[20]): Boolean
    begin
        if ContractNo = '' then
            exit(false);

        ServHour2.Reset();
        ServHour2.SetRange("Service Contract Type", ServHour."Service Contract Type"::Contract);
        ServHour2.SetRange("Service Contract No.", ContractNo);
        exit(ServHour2.FindFirst);
    end;

    local procedure UpdateStartFinishDateTime(DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer; StartingDate: Date; StartingTime: Time; FinishingDate: Date; FinishingTime: Time; Erasing: Boolean)
    var
        ServOrderMgt: Codeunit ServOrderManagement;
        GoOut: Boolean;
        Modifyheader: Boolean;
    begin
        if not ServHeader3.Get(DocumentType, DocumentNo) then
            exit;

        ServItemLine.Reset();
        ServItemLine.SetCurrentKey("Document Type", "Document No.", "Starting Date");
        ServItemLine.SetRange("Document Type", ServHeader3."Document Type");
        ServItemLine.SetRange("Document No.", ServHeader3."No.");
        ServItemLine.SetFilter("Starting Date", '<>%1', 0D);
        ServItemLine.SetFilter("Line No.", '<> %1', LineNo);
        if ServItemLine.Find('-') then begin
            if Erasing then begin
                StartingDate := ServItemLine."Starting Date";
                StartingTime := ServItemLine."Starting Time";
            end;
            repeat
                if ServItemLine."Starting Date" < StartingDate then begin
                    StartingDate := ServItemLine."Starting Date";
                    StartingTime := ServItemLine."Starting Time";
                end else
                    if (ServItemLine."Starting Date" = StartingDate) and
                       (ServItemLine."Starting Time" < StartingTime)
                    then
                        StartingTime := ServItemLine."Starting Time";
            until ServItemLine.Next = 0
        end else
            GoOut := true;

        if not GoOut then begin
            ServItemLine.Reset();
            ServItemLine.SetCurrentKey("Document Type", "Document No.", "Finishing Date");
            ServItemLine.Ascending(false);
            ServItemLine.SetRange("Document Type", ServHeader3."Document Type");
            ServItemLine.SetRange("Document No.", ServHeader3."No.");
            ServItemLine.SetFilter("Finishing Date", '<>%1', 0D);
            ServItemLine.SetFilter("Line No.", '<> %1', LineNo);
            if ServItemLine.Find('-') then
                repeat
                    if ServItemLine."Finishing Date" > FinishingDate then begin
                        FinishingDate := ServItemLine."Finishing Date";
                        FinishingTime := ServItemLine."Finishing Time";
                    end else
                        if (ServItemLine."Finishing Date" = FinishingDate) and
                           (ServItemLine."Finishing Time" > FinishingTime)
                        then
                            FinishingTime := ServItemLine."Finishing Time";
                until ServItemLine.Next = 0;
        end else
            if Erasing then begin
                StartingDate := 0D;
                StartingTime := 0T;
                FinishingDate := 0D;
                FinishingTime := 0T;
            end;

        Modifyheader := false;
        ServHeader3.CalcFields("Contract Serv. Hours Exist");
        if (ServHeader3."Starting Date" <> StartingDate) or
           ((ServHeader3."Starting Date" = StartingDate) and
            (ServHeader3."Starting Time" <> StartingTime))
        then begin
            ServHeader3."Starting Date" := StartingDate;
            ServHeader3."Starting Time" := StartingTime;
            if StartingDate <> 0D then
                ServHeader3."Actual Response Time (Hours)" :=
                  ServOrderMgt.CalcServTime(
                    ServHeader3."Order Date", ServHeader3."Order Time", StartingDate, StartingTime,
                    ServHeader3."Contract No.", ServHeader3."Contract Serv. Hours Exist")
            else
                ServHeader3."Actual Response Time (Hours)" := 0;
            Modifyheader := true;
        end;

        if ((ServHeader3.Status = ServHeader3.Status::Finished) or
            GoOut) and
           ((ServHeader3."Finishing Date" <> FinishingDate) or
            ((ServHeader3."Finishing Date" = FinishingDate) and
             (ServHeader3."Finishing Time" <> FinishingTime)))
        then begin
            ServHeader3."Finishing Date" := FinishingDate;
            ServHeader3."Finishing Time" := FinishingTime;
            ServHeader3."Service Time (Hours)" :=
              ServOrderMgt.CalcServTime(
                StartingDate, StartingTime, FinishingDate, FinishingTime,
                ServHeader3."Contract No.", ServHeader3."Contract Serv. Hours Exist");
            Modifyheader := true;
        end;

        if Modifyheader then
            ServHeader3.Modify();
    end;

    procedure AssistEditSerialNo()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        Clear(ItemLedgEntry);
        GetServHeader;
        ItemLedgEntry.SetCurrentKey("Source Type", "Source No.", "Item No.", "Variant Code");
        ItemLedgEntry.SetRange("Source Type", ItemLedgEntry."Source Type"::Customer);
        ItemLedgEntry.SetRange("Source No.", ServHeader."Customer No.");
        if "Item No." <> '' then
            ItemLedgEntry.SetRange("Item No.", "Item No.");
        if "Variant Code" <> '' then
            ItemLedgEntry.SetRange("Variant Code", "Variant Code");
        ItemLedgEntry.SetFilter("Serial No.", '<>%1', '');
        if PAGE.RunModal(0, ItemLedgEntry) = ACTION::LookupOK then begin
            if "Item No." = '' then begin
                if Description + "Description 2" = '' then begin
                    Item.Get(ItemLedgEntry."Item No.");
                    Description := Item.Description;
                    "Description 2" := Item."Description 2";
                end;
                Validate("Item No.", ItemLedgEntry."Item No.");
            end;
            Validate("Serial No.", ItemLedgEntry."Serial No.");
        end;
    end;

    procedure SetHideDialogBox(DialogBoxVar: Boolean)
    begin
        HideDialogBox := DialogBoxVar;
    end;

    local procedure GetItemTranslation(): Boolean
    var
        ItemTranslation: Record "Item Translation";
    begin
        GetServHeader;
        if not ItemTranslation.Get("Item No.", "Variant Code", ServHeader."Language Code") then
            exit(false);

        Description := ItemTranslation.Description;
        "Description 2" := ItemTranslation."Description 2";

        exit(true);
    end;

    procedure ShowComments(Type: Option General,Fault,Resolution,Accessory,Internal,"Service Item Loaner")
    begin
        ServHeader.Get("Document Type", "Document No.");
        ServHeader.TestField("Customer No.");
        TestField("Line No.");

        ServCommentLine.Reset();
        ServCommentLine.SetRange("Table Name", ServCommentLine."Table Name"::"Service Header");
        ServCommentLine.SetRange("Table Subtype", "Document Type");
        ServCommentLine.SetRange("No.", "Document No.");
        case Type of
            Type::Fault:
                ServCommentLine.SetRange(Type, ServCommentLine.Type::Fault);
            Type::Resolution:
                ServCommentLine.SetRange(Type, ServCommentLine.Type::Resolution);
            Type::Accessory:
                ServCommentLine.SetRange(Type, ServCommentLine.Type::Accessory);
            Type::Internal:
                ServCommentLine.SetRange(Type, ServCommentLine.Type::Internal);
            Type::"Service Item Loaner":
                ServCommentLine.SetRange(Type, ServCommentLine.Type::"Service Item Loaner");
        end;
        ServCommentLine.SetRange("Table Line No.", "Line No.");
        PAGE.RunModal(PAGE::"Service Comment Sheet", ServCommentLine);
    end;

    local procedure RecreateServLines(var ServLine2: Record "Service Line")
    var
        TempServLine: Record "Service Line" temporary;
    begin
        if ServLine2.Find('-') then begin
            ServLine2.LockTable();
            repeat
                TempServLine := ServLine2;
                TempServLine.Insert();
            until ServLine2.Next = 0;

            TempServLine.Find('-');

            repeat
                ServLine2.Get(TempServLine."Document Type", TempServLine."Document No.", TempServLine."Line No.");
                ServLine2.SetHideReplacementDialog(true);
                if TempServLine."No." <> '' then begin
                    ServLine.SetHideCostWarning(true);
                    ServLine2.Validate("No.", TempServLine."No.");
                    ServLine2."Spare Part Action" := TempServLine."Spare Part Action";
                    ServLine2."Component Line No." := TempServLine."Component Line No.";
                    ServLine2."Replaced Item No." := TempServLine."Replaced Item No.";
                    if TempServLine.Quantity <> 0 then
                        ServLine2.Validate(Quantity, TempServLine.Quantity);
                    ServLine2."Location Code" := TempServLine."Location Code";
                    if ServLine2.Type <> ServLine2.Type::" " then begin
                        if ServLine2.Type = ServLine2.Type::Item then begin
                            ServLine2.Validate("Variant Code", TempServLine."Variant Code");
                            if ServLine2."Location Code" <> '' then
                                ServLine2."Bin Code" := TempServLine."Bin Code";
                        end;
                        ServLine2.Validate("Unit of Measure Code", TempServLine."Unit of Measure Code");
                        ServLine2."Fault Reason Code" := TempServLine."Fault Reason Code";
                        ServLine2."Exclude Warranty" := TempServLine."Exclude Warranty";
                        ServLine2."Exclude Contract Discount" := TempServLine."Exclude Contract Discount";
                        ServLine2.Validate(Warranty, TempServLine.Warranty);
                    end;
                    ServLine2.Description := TempServLine.Description;
                    ServLine2."Description 2" := TempServLine."Description 2";
                    OnRecreateServLine(ServLine2, TempServLine);
                end;
                ServLine2.Modify(true);
            until TempServLine.Next = 0;
            TempServLine.DeleteAll();
        end;
    end;

    local procedure CalculateDates()
    begin
        if ServHeader."Order Date" > WorkDate then begin
            if "Starting Date" = 0D then begin
                "Starting Date" := ServHeader."Order Date";
                "Starting Time" := ServHeader."Order Time";
            end;
            "Finishing Date" := "Starting Date";
            Validate("Finishing Time", "Starting Time");
        end else begin
            if "Starting Date" = 0D then begin
                "Starting Date" := WorkDate;
                "Starting Time" := Time;
            end;
            if WorkDate < "Starting Date" then begin
                "Finishing Date" := "Starting Date";
                Validate("Finishing Time", "Starting Time");
            end else begin
                "Finishing Date" := WorkDate;
                if ("Starting Date" = "Finishing Date") and ("Starting Time" > Time) then
                    Validate("Finishing Time", "Starting Time")
                else
                    Validate("Finishing Time", Time);
            end;
        end;
    end;

    local procedure CalculateResponseTimeHours(): Decimal
    begin
        if "Contract No." <> '' then begin
            if "Service Item No." <> '' then begin
                ServContractLine.Reset();
                ServContractLine.SetRange("Contract Type", ServContractLine."Contract Type"::Contract);
                ServContractLine.SetRange("Contract No.", "Contract No.");
                ServContractLine.SetRange("Service Item No.", "Service Item No.");
                if ServContractLine.FindFirst then
                    if ServContractLine."Response Time (Hours)" > 0 then
                        exit(ServContractLine."Response Time (Hours)");
            end;

            if ServContract.Get(ServContract."Contract Type"::Contract, "Contract No.") then
                if ServContract."Response Time (Hours)" > 0 then
                    exit(ServContract."Response Time (Hours)");
        end;

        if "Service Item No." <> '' then
            if ServItem.Get("Service Item No.") then
                if ServItem."Response Time (Hours)" > 0 then
                    exit(ServItem."Response Time (Hours)");

        if "Service Item Group Code" <> '' then
            if ServItemGr.Get("Service Item Group Code") then
                if ServItemGr."Default Response Time (Hours)" <> 0 then
                    exit(ServItemGr."Default Response Time (Hours)");

        ServMgtSetup.Get();
        exit(ServMgtSetup."Default Response Time (Hours)");
    end;

    procedure UpdateResponseTimeHours()
    begin
        OnBeforeUpdateResponseTimeHours(Rec);

        if not SkipResponseTimeHrsUpdate then begin
            if "Response Time (Hours)" <> xRec."Response Time (Hours)" then
                Validate("Response Time (Hours)", CalculateResponseTimeHours)
            else
                if "Response Date" = 0D then
                    Validate("Response Time (Hours)", CalculateResponseTimeHours)
                else
                    "Response Time (Hours)" := CalculateResponseTimeHours;
            SkipResponseTimeHrsUpdate := false
        end;
    end;

    procedure UpdateServiceOrderChangeLog(var OldServItemLine: Record "Service Item Line")
    begin
        if "Response Date" <> OldServItemLine."Response Date" then
            ServLogMgt.ServItemLineResponseDateChange(Rec, OldServItemLine);

        if "Response Time" <> OldServItemLine."Response Time" then
            ServLogMgt.ServItemLineResponseTimeChange(Rec, OldServItemLine);

        if "Repair Status Code" <> OldServItemLine."Repair Status Code" then
            ServLogMgt.ServHeaderRepairStatusChange(Rec, OldServItemLine);
    end;

    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20]; Type3: Integer; No3: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        SourceCodeSetup.Get();

        if "Document No." = '' then
            exit;

        GetServHeader;

        TableID[1] := Type1;
        No[1] := No1;
        TableID[2] := Type2;
        No[2] := No2;
        TableID[3] := Type3;
        No[3] := No3;

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';

        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, TableID, No, SourceCodeSetup."Service Management",
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", ServHeader."Dimension Set ID", DATABASE::"Service Header");
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure ShowDimensions()
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";

        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2 %3', "Document Type", "Document No.", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        if OldDimSetID <> "Dimension Set ID" then begin
            Modify;
            if ServLineExists then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    local procedure ServLineExists(): Boolean
    begin
        ServLine.Reset();
        ServLine.SetRange("Document Type", "Document Type");
        ServLine.SetRange("Document No.", "Document No.");
        exit(ServLine.Find('-'));
    end;

    procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        ConfirmManagement: Codeunit "Confirm Management";
        NewDimSetID: Integer;
    begin
        // Update all lines with changed dimensions.

        if NewParentDimSetID = OldParentDimSetID then
            exit;
        if not (HideDialogBox or ConfirmManagement.GetResponseOrDefault(Text060, true)) then
            exit;

        ServLine.Reset();
        ServLine.SetRange("Document Type", "Document Type");
        ServLine.SetRange("Document No.", "Document No.");
        ServLine.LockTable();
        if ServLine.Find('-') then
            repeat
                NewDimSetID := DimMgt.GetDeltaDimSetID(ServLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if ServLine."Dimension Set ID" <> NewDimSetID then begin
                    ServLine."Dimension Set ID" := NewDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      ServLine."Dimension Set ID", ServLine."Shortcut Dimension 1 Code", ServLine."Shortcut Dimension 2 Code");
                    ServLine.Modify();
                end;
            until ServLine.Next = 0;
    end;

    procedure SetServItemInfo(ServItem: Record "Service Item")
    begin
        "Item No." := ServItem."Item No.";
        "Serial No." := ServItem."Serial No.";
        "Variant Code" := ServItem."Variant Code";
        "Warranty Starting Date (Parts)" := ServItem."Warranty Starting Date (Parts)";
        "Warranty Ending Date (Parts)" := ServItem."Warranty Ending Date (Parts)";
        "Warranty Starting Date (Labor)" := ServItem."Warranty Starting Date (Labor)";
        "Warranty Ending Date (Labor)" := ServItem."Warranty Ending Date (Labor)";
        "Warranty % (Parts)" := ServItem."Warranty % (Parts)";
        "Warranty % (Labor)" := ServItem."Warranty % (Labor)";
        Description := ServItem.Description;
        "Description 2" := ServItem."Description 2";
        Priority := ServItem.Priority;
        "Vendor No." := ServItem."Vendor No.";
        "Vendor Item No." := ServItem."Vendor Item No.";
        CheckWarranty(ServHeader."Order Date");

        OnAfterSetServItemInfo(Rec, xRec, ServItem);
    end;

    procedure CheckTempDateErrorDate(Tempdate: Date; ErrorDate: Date; Caption1: Text[30]; Caption2: Text[30])
    begin
        if Tempdate > ErrorDate then
            Error(Text045, FieldCaption("Response Date"), TableCaption, Caption1, Caption2);
    end;

    local procedure CheckServHourStartingDate(ServiceHour: Record "Service Hour")
    begin
        if ServiceHour."Starting Date" <> 0D then
            Error(
              Text044,
              ServiceHour.FieldCaption("Ending Time"),
              ServiceHour.Day,
              ServiceHour.FieldCaption("Starting Date"),
              ServiceHour."Starting Date",
              Text057);
    end;

    local procedure LendLoanerWithConfirmation()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if "Loaner No." = '' then
            exit;
        if ConfirmManagement.GetResponseOrDefault(
             StrSubstNo(Text029, Loaner.TableCaption, "Loaner No."), true)
        then
            ServLoanerMgt.LendLoaner(Rec)
        else
            "Loaner No." := '';
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignItemValues(var ServiceItemLine: Record "Service Item Line"; var xServiceItemLine: Record "Service Item Line"; Item: Record Item; ServiceHeader: Record "Service Header"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetServItemInfo(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line"; ServiceItem: Record "Service Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnModify(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckServItemCustomer(ServiceHeader: Record "Service Header"; ServiceItem: Record "Service Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateResponseTimeHours(var ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateSerialNo(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateWarranty(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateWarrantyParts(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateWarrantyLabor(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckWarrantyOnAfterSetWarranty(var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateServLine(var ServiceLine: Record "Service Line"; TempServiceLine: Record "Service Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateContractNoOnBeforeValidateServicePeriod(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateServiceItemNoOnBeforeValidateServicePeriod(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;
}

