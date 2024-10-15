table 5409 "Prod. Order Routing Line"
{
    Caption = 'Prod. Order Routing Line';
    DrillDownPageID = "Prod. Order Routing";
    LookupPageID = "Prod. Order Routing";
    Permissions = TableData "Prod. Order Capacity Need" = rimd;

    fields
    {
        field(1; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            TableRelation = "Routing Header";
        }
        field(3; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
            Editable = false;
        }
        field(4; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            NotBlank = true;

            trigger OnValidate()
            begin
                SetRecalcStatus;

                GetLine;
                "Starting Time" := ProdOrderLine."Starting Time";
                "Ending Time" := ProdOrderLine."Ending Time";
                "Starting Date" := ProdOrderLine."Starting Date";
                "Ending Date" := ProdOrderLine."Ending Date";
            end;
        }
        field(5; "Next Operation No."; Code[30])
        {
            Caption = 'Next Operation No.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                GetLine;
                OnBeforeTerminationProcessesErr(IsHandled);
                if not IsHandled then
                    if (xRec."Next Operation No." = '') and ("Next Operation No." <> '') and NoTerminationProcessesExist then
                        Error(NoTerminationProcessesErr);

                SetRecalcStatus;
            end;
        }
        field(6; "Previous Operation No."; Code[30])
        {
            Caption = 'Previous Operation No.';

            trigger OnValidate()
            begin
                SetRecalcStatus;
            end;
        }
        field(7; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Work Center,Machine Center';
            OptionMembers = "Work Center","Machine Center";

            trigger OnValidate()
            begin
                SetRecalcStatus;

                "No." := '';
                "Work Center No." := '';
                "Work Center Group Code" := '';

                ModifyCapNeedEntries;
            end;
        }
        field(8; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = IF (Type = CONST("Work Center")) "Work Center"
            ELSE
            IF (Type = CONST("Machine Center")) "Machine Center";

            trigger OnValidate()
            var
                PurchLine: Record "Purchase Line";
                PurchHeader: Record "Purchase Header";
                SubcontractingManagement: Codeunit SubcontractingManagement;
                LicensePermission: Record "License Permission";
            begin
                if LicensePermission.Get(LicensePermission."Object Type"::Codeunit, CODEUNIT::SubcontractingManagement) then
                    if LicensePermission."Execute Permission" <> LicensePermission."Execute Permission"::" " then begin
                        if Status = Status::Released then
                            if SubcontractingManagement.FindSubcOrder(Rec, PurchLine, PurchHeader) then
                                Error(Text1130001, Status, TableCaption, "Operation No.", PurchLine."Document No.");
                        if (xRec."No." <> "No.") and ("Routing Link Code" <> '') then
                            SubcontractingManagement.UpdLinkedComponents(Rec, true);
                    end;

                SetRecalcStatus;

                if "No." = '' then
                    exit;

                case Type of
                    Type::"Work Center":
                        begin
                            WorkCenter.Get("No.");
                            WorkCenter.TestField(Blocked, false);
                            WorkCenterTransferFields;
                        end;
                    Type::"Machine Center":
                        begin
                            MachineCenter.Get("No.");
                            MachineCenter.TestField(Blocked, false);
                            MachineCtrTransferFields;
                        end;
                end;
                ModifyCapNeedEntries;

                GetLine;
                if (ProdOrderLine."Routing Type" = ProdOrderLine."Routing Type"::Serial) or (xRec."No." <> '') then
                    CalcStartingEndingDates(Direction::Forward);

                OnAfterValidateNo(Rec, xRec, ProdOrderLine);
            end;
        }
        field(9; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            Editable = false;
            TableRelation = "Work Center";
        }
        field(10; "Work Center Group Code"; Code[10])
        {
            Caption = 'Work Center Group Code';
            Editable = false;
            TableRelation = "Work Center Group";
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(12; "Setup Time"; Decimal)
        {
            Caption = 'Setup Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalcStartingEndingDates(Direction::Forward);
            end;
        }
        field(13; "Run Time"; Decimal)
        {
            Caption = 'Run Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalcStartingEndingDates(Direction::Forward);
            end;
        }
        field(14; "Wait Time"; Decimal)
        {
            Caption = 'Wait Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalcStartingEndingDates(Direction::Forward);
            end;
        }
        field(15; "Move Time"; Decimal)
        {
            Caption = 'Move Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalcStartingEndingDates(Direction::Forward);
            end;
        }
        field(16; "Fixed Scrap Quantity"; Decimal)
        {
            Caption = 'Fixed Scrap Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                SetRecalcStatus;
            end;
        }
        field(17; "Lot Size"; Decimal)
        {
            Caption = 'Lot Size';
            DecimalPlaces = 0 : 5;
        }
        field(18; "Scrap Factor %"; Decimal)
        {
            Caption = 'Scrap Factor %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                SetRecalcStatus;
            end;
        }
        field(19; "Setup Time Unit of Meas. Code"; Code[10])
        {
            Caption = 'Setup Time Unit of Meas. Code';
            TableRelation = "Capacity Unit of Measure";

            trigger OnValidate()
            begin
                CalcStartingEndingDates(Direction::Forward);
            end;
        }
        field(20; "Run Time Unit of Meas. Code"; Code[10])
        {
            Caption = 'Run Time Unit of Meas. Code';
            TableRelation = "Capacity Unit of Measure";

            trigger OnValidate()
            begin
                CalcStartingEndingDates(Direction::Forward);
            end;
        }
        field(21; "Wait Time Unit of Meas. Code"; Code[10])
        {
            Caption = 'Wait Time Unit of Meas. Code';
            TableRelation = "Capacity Unit of Measure";

            trigger OnValidate()
            begin
                CalcStartingEndingDates(Direction::Forward);
            end;
        }
        field(22; "Move Time Unit of Meas. Code"; Code[10])
        {
            Caption = 'Move Time Unit of Meas. Code';
            TableRelation = "Capacity Unit of Measure";

            trigger OnValidate()
            begin
                CalcStartingEndingDates(Direction::Forward);
            end;
        }
        field(27; "Minimum Process Time"; Decimal)
        {
            Caption = 'Minimum Process Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(28; "Maximum Process Time"; Decimal)
        {
            Caption = 'Maximum Process Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(30; "Concurrent Capacities"; Decimal)
        {
            Caption = 'Concurrent Capacities';
            DecimalPlaces = 0 : 5;
            InitValue = 1;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalcStartingEndingDates(Direction::Forward);
            end;
        }
        field(31; "Send-Ahead Quantity"; Decimal)
        {
            Caption = 'Send-Ahead Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalcStartingEndingDates(Direction::Forward);
            end;
        }
        field(34; "Routing Link Code"; Code[10])
        {
            Caption = 'Routing Link Code';
            Editable = false;
            TableRelation = "Routing Link";

            trigger OnValidate()
            var
                ProdOrdRtngLine2: Record "Prod. Order Routing Line";
                SubcontractingManagement: Codeunit SubcontractingManagement;
            begin
                ProdOrdRtngLine2 := Rec;
                ProdOrdRtngLine2.SetRecFilter;
                ProdOrdRtngLine2.SetRange("Operation No.");
                ProdOrdRtngLine2.SetRange("Routing Link Code", "Routing Link Code");
                if ProdOrdRtngLine2.Find('-') then
                    if not Confirm(Text1130003, false, FieldCaption("Routing Link Code"), "Routing Link Code") then
                        Error(Text1130004);
                if "Routing Link Code" <> xRec."Routing Link Code" then
                    if xRec."Routing Link Code" <> '' then begin
                        SubcontractingManagement.DelLocationLinkedComponents(xRec, true);
                        if "Routing Link Code" <> '' then
                            SubcontractingManagement.UpdLinkedComponents(Rec, false);
                    end else
                        if "Routing Link Code" <> '' then
                            SubcontractingManagement.UpdLinkedComponents(Rec, true);

                if "Routing Link Code" <> '' then
                    TestField("WIP Item", false);
            end;
        }
        field(35; "Standard Task Code"; Code[10])
        {
            Caption = 'Standard Task Code';
            TableRelation = "Standard Task";

            trigger OnValidate()
            var
                StandardTask: Record "Standard Task";
                StdTaskTool: Record "Standard Task Tool";
                StdTaskPersonnel: Record "Standard Task Personnel";
                StdTaskQltyMeasure: Record "Standard Task Quality Measure";
                StdTaskComment: Record "Standard Task Description";
            begin
                if (Type = Type::"Work Center") then begin
                    WorkCenter.Get("No.");
                    GetSubcPricelist;
                end;

                if "Standard Task Code" = '' then
                    exit;

                StandardTask.Get("Standard Task Code");
                Description := StandardTask.Description;

                DeleteRelations;

                StdTaskTool.SetRange("Standard Task Code", "Standard Task Code");
                if StdTaskTool.Find('-') then
                    repeat
                        ProdOrderRoutTool.Status := Status;
                        ProdOrderRoutTool."Prod. Order No." := "Prod. Order No.";
                        ProdOrderRoutTool."Routing Reference No." := "Routing Reference No.";
                        ProdOrderRoutTool."Routing No." := "Routing No.";
                        ProdOrderRoutTool."Operation No." := "Operation No.";
                        ProdOrderRoutTool."Line No." := StdTaskTool."Line No.";
                        ProdOrderRoutTool."No." := StdTaskTool."No.";
                        ProdOrderRoutTool.Description := StdTaskTool.Description;
                        ProdOrderRoutTool.Insert;
                        OnAfterTransferFromStdTaskTool(ProdOrderRoutTool, StdTaskTool);
                    until StdTaskTool.Next = 0;

                StdTaskPersonnel.SetRange("Standard Task Code", "Standard Task Code");
                if StdTaskPersonnel.Find('-') then
                    repeat
                        ProdOrderRtngPersonnel.Status := Status;
                        ProdOrderRtngPersonnel."Prod. Order No." := "Prod. Order No.";
                        ProdOrderRtngPersonnel."Routing Reference No." := "Routing Reference No.";
                        ProdOrderRtngPersonnel."Routing No." := "Routing No.";
                        ProdOrderRtngPersonnel."Operation No." := "Operation No.";
                        ProdOrderRtngPersonnel."Line No." := StdTaskPersonnel."Line No.";
                        ProdOrderRtngPersonnel."No." := StdTaskPersonnel."No.";
                        ProdOrderRtngPersonnel.Description := StdTaskPersonnel.Description;
                        ProdOrderRtngPersonnel.Insert;
                        OnAfterTransferFromStdTaskPersonnel(ProdOrderRtngPersonnel, StdTaskPersonnel);
                    until StdTaskPersonnel.Next = 0;

                StdTaskQltyMeasure.SetRange("Standard Task Code", "Standard Task Code");
                if StdTaskQltyMeasure.Find('-') then
                    repeat
                        ProdOrderRtngQltyMeas.Status := Status;
                        ProdOrderRtngQltyMeas."Prod. Order No." := "Prod. Order No.";
                        ProdOrderRtngQltyMeas."Routing Reference No." := "Routing Reference No.";
                        ProdOrderRtngQltyMeas."Routing No." := "Routing No.";
                        ProdOrderRtngQltyMeas."Operation No." := "Operation No.";
                        ProdOrderRtngQltyMeas."Line No." := StdTaskQltyMeasure."Line No.";
                        ProdOrderRtngQltyMeas."Qlty Measure Code" := StdTaskQltyMeasure."Qlty Measure Code";
                        ProdOrderRtngQltyMeas.Description := StdTaskQltyMeasure.Description;
                        ProdOrderRtngQltyMeas."Min. Value" := StdTaskQltyMeasure."Min. Value";
                        ProdOrderRtngQltyMeas."Max. Value" := StdTaskQltyMeasure."Max. Value";
                        ProdOrderRtngQltyMeas."Mean Tolerance" := StdTaskQltyMeasure."Mean Tolerance";
                        ProdOrderRtngQltyMeas.Insert;
                        OnAfterTransferFromStdTaskQltyMeasure(ProdOrderRtngQltyMeas, StdTaskQltyMeasure);
                    until StdTaskQltyMeasure.Next = 0;

                StdTaskComment.SetRange("Standard Task Code", "Standard Task Code");
                if StdTaskComment.Find('-') then
                    repeat
                        ProdOrderRtngComment.Status := Status;
                        ProdOrderRtngComment."Prod. Order No." := "Prod. Order No.";
                        ProdOrderRtngComment."Routing Reference No." := "Routing Reference No.";
                        ProdOrderRtngComment."Routing No." := "Routing No.";
                        ProdOrderRtngComment."Operation No." := "Operation No.";
                        ProdOrderRtngComment."Line No." := StdTaskComment."Line No.";
                        ProdOrderRtngComment.Comment := StdTaskComment.Text;
                        ProdOrderRtngComment.Insert;
                        OnAfterTransferFromStdTaskComment(ProdOrderRtngComment, StdTaskComment);
                    until StdTaskComment.Next = 0;
            end;
        }
        field(40; "Unit Cost per"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost per';
            MinValue = 0;

            trigger OnValidate()
            begin
                GLSetup.Get;
                "Direct Unit Cost" :=
                  Round(
                    ("Unit Cost per" - "Overhead Rate") /
                    (1 + "Indirect Cost %" / 100),
                    GLSetup."Unit-Amount Rounding Precision");

                CalcStartingEndingDates(Direction::Forward);
            end;
        }
        field(41; Recalculate; Boolean)
        {
            Caption = 'Recalculate';
        }
        field(50; "Sequence No. (Forward)"; Integer)
        {
            Caption = 'Sequence No. (Forward)';
            Editable = false;
        }
        field(51; "Sequence No. (Backward)"; Integer)
        {
            Caption = 'Sequence No. (Backward)';
            Editable = false;
        }
        field(52; "Fixed Scrap Qty. (Accum.)"; Decimal)
        {
            Caption = 'Fixed Scrap Qty. (Accum.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(53; "Scrap Factor % (Accumulated)"; Decimal)
        {
            Caption = 'Scrap Factor % (Accumulated)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(55; "Sequence No. (Actual)"; Integer)
        {
            Caption = 'Sequence No. (Actual)';
            Editable = false;
        }
        field(56; "Direct Unit Cost"; Decimal)
        {
            Caption = 'Direct Unit Cost';
            DecimalPlaces = 2 : 5;

            trigger OnValidate()
            begin
                Validate("Indirect Cost %");
            end;
        }
        field(57; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                GLSetup.Get;
                "Unit Cost per" :=
                  Round(
                    "Direct Unit Cost" * (1 + "Indirect Cost %" / 100) + "Overhead Rate",
                    GLSetup."Unit-Amount Rounding Precision");
            end;
        }
        field(58; "Overhead Rate"; Decimal)
        {
            Caption = 'Overhead Rate';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Indirect Cost %");
            end;
        }
        field(70; "Starting Time"; Time)
        {
            Caption = 'Starting Time';

            trigger OnValidate()
            begin
                CalcStartingEndingDates(Direction::Forward);
            end;
        }
        field(71; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                Validate("Starting Time");
            end;
        }
        field(72; "Ending Time"; Time)
        {
            Caption = 'Ending Time';

            trigger OnValidate()
            begin
                CalcStartingEndingDates(Direction::Backward);
            end;
        }
        field(73; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                Validate("Ending Time");
            end;
        }
        field(74; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Simulated,Planned,Firm Planned,Released,Finished';
            OptionMembers = Simulated,Planned,"Firm Planned",Released,Finished;
        }
        field(75; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            Editable = false;
            NotBlank = true;
            TableRelation = "Production Order"."No." WHERE(Status = FIELD(Status));
        }
        field(76; "Unit Cost Calculation"; Option)
        {
            Caption = 'Unit Cost Calculation';
            OptionCaption = 'Time,Units';
            OptionMembers = Time,Units;
        }
        field(77; "Input Quantity"; Decimal)
        {
            Caption = 'Input Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(78; "Critical Path"; Boolean)
        {
            Caption = 'Critical Path';
            Editable = false;
        }
        field(79; "Routing Status"; Option)
        {
            Caption = 'Routing Status';
            OptionCaption = ' ,Planned,In Progress,Finished';
            OptionMembers = " ",Planned,"In Progress",Finished;

            trigger OnValidate()
            var
                ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
            begin
                if (xRec."Routing Status" = xRec."Routing Status"::Finished) and (xRec."Routing Status" <> "Routing Status") then
                    Error(Text008, FieldCaption("Routing Status"), xRec."Routing Status", "Routing Status");

                if ("Routing Status" = "Routing Status"::Finished) and (xRec."Routing Status" <> "Routing Status") then begin
                    if not Confirm(Text009, false, FieldCaption("Routing Status"), "Routing Status") then
                        Error('');

                    ProdOrderCapacityNeed.SetCurrentKey(
                      Status, "Prod. Order No.", "Requested Only", "Routing No.", "Routing Reference No.", "Operation No.", "Line No.");
                    ProdOrderCapacityNeed.SetRange(Status, Status);
                    ProdOrderCapacityNeed.SetRange("Prod. Order No.", "Prod. Order No.");
                    ProdOrderCapacityNeed.SetRange("Requested Only", false);
                    ProdOrderCapacityNeed.SetRange("Routing No.", "Routing No.");
                    ProdOrderCapacityNeed.SetRange("Routing Reference No.", "Routing Reference No.");
                    ProdOrderCapacityNeed.SetRange("Operation No.", "Operation No.");
                    ProdOrderCapacityNeed.ModifyAll("Allocated Time", 0);
                end;
            end;
        }
        field(81; "Flushing Method"; Option)
        {
            Caption = 'Flushing Method';
            InitValue = Manual;
            OptionCaption = 'Manual,Forward,Backward';
            OptionMembers = Manual,Forward,Backward;
        }
        field(90; "Expected Operation Cost Amt."; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Expected Operation Cost Amt.';
            Editable = false;
        }
        field(91; "Expected Capacity Need"; Decimal)
        {
            Caption = 'Expected Capacity Need';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = Normal;
        }
        field(96; "Expected Capacity Ovhd. Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Expected Capacity Ovhd. Cost';
            Editable = false;
        }
        field(98; "Starting Date-Time"; DateTime)
        {
            Caption = 'Starting Date-Time';

            trigger OnValidate()
            begin
                "Starting Date" := DT2Date("Starting Date-Time");
                "Starting Time" := DT2Time("Starting Date-Time");
                Validate("Starting Time");
            end;
        }
        field(99; "Ending Date-Time"; DateTime)
        {
            Caption = 'Ending Date-Time';

            trigger OnValidate()
            begin
                "Ending Date" := DT2Date("Ending Date-Time");
                "Ending Time" := DT2Time("Ending Date-Time");
                Validate("Ending Time");
            end;
        }
        field(100; "Schedule Manually"; Boolean)
        {
            Caption = 'Schedule Manually';
        }
        field(101; "Location Code"; Code[10])
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Location Code';
            Editable = false;
        }
        field(7301; "Open Shop Floor Bin Code"; Code[20])
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Open Shop Floor Bin Code';
            Editable = false;
        }
        field(7302; "To-Production Bin Code"; Code[20])
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'To-Production Bin Code';
            Editable = false;
        }
        field(7303; "From-Production Bin Code"; Code[20])
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'From-Production Bin Code';
            Editable = false;
        }
        field(12180; "WIP Item"; Boolean)
        {
            Caption = 'WIP Item';

            trigger OnValidate()
            begin
                if "WIP Item" then begin
                    TestField(Type, Type::"Work Center");
                    WorkCenter.Get("No.");
                    WorkCenter.TestField("Subcontractor No.");
                    TestField("Routing Link Code", '');
                end else begin
                    CalcFields("Qty. WIP on Subcontractors");
                    TestField("Qty. WIP on Subcontractors", 0);
                end;
            end;
        }
        field(12181; "Qty. WIP on Subcontractors"; Decimal)
        {
            CalcFormula = Sum ("Capacity Ledger Entry"."WIP Item Qty." WHERE("Order Type" = CONST(Production),
                                                                             "Order No." = FIELD("Prod. Order No."),
                                                                             "Routing Reference No." = FIELD("Routing Reference No."),
                                                                             "Operation No." = FIELD("Operation No."),
                                                                             Type = CONST("Work Center"),
                                                                             "Subcontr. Purch. Order No." = FIELD("Purchase Order Filter")));
            Caption = 'Qty. WIP on Subcontractors';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(12182; "Qty. WIP on Transfer Order"; Decimal)
        {
            CalcFormula = Sum ("Transfer Line"."WIP Outstanding Qty. (Base)" WHERE("Prod. Order No." = FIELD("Prod. Order No."),
                                                                                   "Routing No." = FIELD("Routing No."),
                                                                                   "Routing Reference No." = FIELD("Routing Reference No."),
                                                                                   "Operation No." = FIELD("Operation No."),
                                                                                   "Subcontr. Purch. Order No." = FIELD("Purchase Order Filter"),
                                                                                   "Derived From Line No." = CONST(0)));
            Caption = 'Qty. WIP on Transfer Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(12183; "Purchase Order Filter"; Code[20])
        {
            Caption = 'Purchase Order Filter';
            FieldClass = FlowFilter;
            TableRelation = "Purchase Header"."No." WHERE("Document Type" = CONST(Order),
                                                           "Subcontracting Order" = CONST(true));
        }
    }

    keys
    {
        key(Key1; Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.")
        {
            Clustered = true;
        }
        key(Key2; "Prod. Order No.", "Routing Reference No.", Status, "Routing No.", "Operation No.")
        {
        }
        key(Key3; Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Sequence No. (Forward)")
        {
        }
        key(Key4; Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Sequence No. (Backward)")
        {
        }
        key(Key5; Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Sequence No. (Actual)")
        {
            SumIndexFields = "Expected Operation Cost Amt.";
        }
        key(Key6; "Work Center No.")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Expected Operation Cost Amt.";
        }
        key(Key7; Type, "No.", "Starting Date")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Expected Operation Cost Amt.";
        }
        key(Key8; Status, "Work Center No.")
        {
            SumIndexFields = "Expected Operation Cost Amt.";
        }
        key(Key9; "Prod. Order No.", Status, "Flushing Method")
        {
        }
        key(Key10; "Starting Date", "Starting Time", "Routing Status")
        {
        }
        key(Key11; "Ending Date", "Ending Time", "Routing Status")
        {
        }
        key(Key12; Type, "No.", Status)
        {
            SumIndexFields = "Expected Operation Cost Amt.";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
        PurchLine: Record "Purchase Line";
        PurchHeader: Record "Purchase Header";
        SubcontractingManagement: Codeunit SubcontractingManagement;
        SubcontractorPrices: Record "Subcontractor Prices";
    begin
        if Status = Status::Finished then
            Error(Text006, Status, TableCaption);

        if Status = Status::Released then begin
            CapLedgEntry.SetRange("Order Type", CapLedgEntry."Order Type"::Production);
            CapLedgEntry.SetRange("Order No.", "Prod. Order No.");
            CapLedgEntry.SetRange("Routing Reference No.", "Routing Reference No.");
            CapLedgEntry.SetRange("Routing No.", "Routing No.");
            CapLedgEntry.SetRange("Operation No.", "Operation No.");
            if not CapLedgEntry.IsEmpty then
                Error(
                  Text000,
                  Status, TableCaption, "Operation No.", CapLedgEntry.TableCaption);
            if SubcontractorPrices.ReadPermission then begin
                if SubcontractingManagement.FindSubcOrder(Rec, PurchLine, PurchHeader) then
                    Error(Text1130002, Status, TableCaption, "Operation No.", PurchLine."Document No.");
                if ("Routing Link Code" <> '') and (WorkCenter."Subcontractor No." <> '') then
                    SubcontractingManagement.DelLocationLinkedComponents(Rec, false);
            end;
        end;

        DeleteRelations;

        UpdateComponentsBin(2); // from trigger = delete
    end;

    trigger OnInsert()
    begin
        TestField("Routing No.");
        if Status = Status::Finished then
            Error(Text006, Status, TableCaption);

        if "Next Operation No." = '' then
            SetNextOperations(Rec);

        UpdateComponentsBin(0); // from trigger = insert
    end;

    trigger OnModify()
    begin
        if Status = Status::Finished then
            Error(Text006, Status, TableCaption);

        UpdateComponentsBin(1); // from trigger = modify
    end;

    trigger OnRename()
    begin
        Error(Text001, TableCaption);
    end;

    var
        Text000: Label 'You cannot delete %1 %2 %3 because there is at least one %4 associated with it.', Comment = '%1 = Document status; %2 = Table Caption; %3 = Field Value; %4 = Table Caption';
        Text001: Label 'You cannot rename a %1.';
        Text002: Label 'This routing line cannot be moved because of critical work centers in previous operations';
        Text003: Label 'This routing line cannot be moved because of critical work centers in next operations';
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrderRoutTool: Record "Prod. Order Routing Tool";
        ProdOrderRtngPersonnel: Record "Prod. Order Routing Personnel";
        ProdOrderRtngQltyMeas: Record "Prod. Order Rtng Qlty Meas.";
        ProdOrderRtngComment: Record "Prod. Order Rtng Comment Line";
        GLSetup: Record "General Ledger Setup";
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
        PurchLine: Record "Purchase Line";
        TempErrorMessage: Record "Error Message" temporary;
        CalcProdOrder: Codeunit "Calculate Prod. Order";
        ProdOrderRouteMgt: Codeunit "Prod. Order Route Management";
        Text004: Label 'Some routing lines are referring to the operation just deleted. The references are\in the fields %1 and %2.\\This may have to be corrected as a routing line referring to a non-existent\operation will lead to serious errors in capacity planning.\\Do you want to see a list of the lines in question?\(Access the columns Next Operation No. and Previous Operation No.)';
        Text005: Label 'Routing Lines referring to deleted Operation No. %1';
        Text006: Label 'A %1 %2 can not be inserted, modified, or deleted.';
        Direction: Option Forward,Backward;
        Text1130001: Label 'You can not modify %1 %2 %3 because exists Sucontractor Purchase Order %4 associated with it.';
        Text1130002: Label 'You can not delete %1 %2 %3 because exists Sucontractor Purchase Order %4 associated with it.';
        Text1130003: Label '%1 used more than once on this Routing. Do you want to update it anyway ?';
        Text1130004: Label 'Update cancelled.';
        Text007: Label 'You cannot change %1, because there is at least one %2 associated with %3 %4 %5.';
        Text008: Label 'You cannot change the %1 from %2 to %3.';
        Text009: Label 'If you change the %1 to %2, then all related allocated capacity will be deleted, and you will not be able to change the %1 of the operation again.\\Are you sure that you want to continue?';
        SkipUpdateOfCompBinCodes: Boolean;
        TimeShiftedOnParentLineMsg: Label 'The production starting date-time of the end item has been moved forward because a subassembly is taking longer than planned.';
        NoTerminationProcessesErr: Label 'On the last operation, the Next Operation No. field must be empty.';

    procedure Caption(): Text
    var
        ProdOrder: Record "Production Order";
    begin
        if GetFilters = '' then
            exit('');

        if not ProdOrder.Get(Status, "Prod. Order No.") then
            exit('');

        exit(
          StrSubstNo('%1 %2 %3',
            "Prod. Order No.", ProdOrder.Description, "Routing No."));
    end;

    local procedure GetLine()
    begin
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderLine.SetRange("Routing No.", "Routing No.");
        ProdOrderLine.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderLine.Find('-');
    end;

    [Scope('OnPrem')]
    procedure CopyFromPlanningRoutingLine(PlanningRoutingLine: Record "Planning Routing Line")
    begin
        "Operation No." := PlanningRoutingLine."Operation No.";
        "Next Operation No." := PlanningRoutingLine."Next Operation No.";
        "Previous Operation No." := PlanningRoutingLine."Previous Operation No.";
        Type := PlanningRoutingLine.Type;
        "No." := PlanningRoutingLine."No.";
        "Work Center No." := PlanningRoutingLine."Work Center No.";
        "Work Center Group Code" := PlanningRoutingLine."Work Center Group Code";
        Description := PlanningRoutingLine.Description;
        "Setup Time" := PlanningRoutingLine."Setup Time";
        "Run Time" := PlanningRoutingLine."Run Time";
        "Wait Time" := PlanningRoutingLine."Wait Time";
        "Move Time" := PlanningRoutingLine."Move Time";
        "Fixed Scrap Quantity" := PlanningRoutingLine."Fixed Scrap Quantity";
        "Lot Size" := PlanningRoutingLine."Lot Size";
        "Scrap Factor %" := PlanningRoutingLine."Scrap Factor %";
        "Setup Time Unit of Meas. Code" := PlanningRoutingLine."Setup Time Unit of Meas. Code";
        "Run Time Unit of Meas. Code" := PlanningRoutingLine."Run Time Unit of Meas. Code";
        "Wait Time Unit of Meas. Code" := PlanningRoutingLine."Wait Time Unit of Meas. Code";
        "Move Time Unit of Meas. Code" := PlanningRoutingLine."Move Time Unit of Meas. Code";
        "Minimum Process Time" := PlanningRoutingLine."Minimum Process Time";
        "Maximum Process Time" := PlanningRoutingLine."Maximum Process Time";
        "Concurrent Capacities" := PlanningRoutingLine."Concurrent Capacities";
        "Send-Ahead Quantity" := PlanningRoutingLine."Send-Ahead Quantity";
        "Routing Link Code" := PlanningRoutingLine."Routing Link Code";
        "Standard Task Code" := PlanningRoutingLine."Standard Task Code";
        "Unit Cost per" := PlanningRoutingLine."Unit Cost per";
        Recalculate := PlanningRoutingLine.Recalculate;
        "Sequence No. (Forward)" := PlanningRoutingLine."Sequence No.(Forward)";
        "Sequence No. (Backward)" := PlanningRoutingLine."Sequence No.(Backward)";
        "Fixed Scrap Qty. (Accum.)" := PlanningRoutingLine."Fixed Scrap Qty. (Accum.)";
        "Scrap Factor % (Accumulated)" := PlanningRoutingLine."Scrap Factor % (Accumulated)";
        "Sequence No. (Actual)" := PlanningRoutingLine."Sequence No. (Actual)";
        "Starting Time" := PlanningRoutingLine."Starting Time";
        "Starting Date" := PlanningRoutingLine."Starting Date";
        "Ending Time" := PlanningRoutingLine."Ending Time";
        "Ending Date" := PlanningRoutingLine."Ending Date";
        "Unit Cost Calculation" := PlanningRoutingLine."Unit Cost Calculation";
        "Input Quantity" := PlanningRoutingLine."Input Quantity";
        "Critical Path" := PlanningRoutingLine."Critical Path";
        "Direct Unit Cost" := PlanningRoutingLine."Direct Unit Cost";
        "Indirect Cost %" := PlanningRoutingLine."Indirect Cost %";
        "Overhead Rate" := PlanningRoutingLine."Overhead Rate";
        "Expected Operation Cost Amt." := PlanningRoutingLine."Expected Operation Cost Amt.";
        "Expected Capacity Ovhd. Cost" := PlanningRoutingLine."Expected Capacity Ovhd. Cost";
        "Expected Capacity Need" := PlanningRoutingLine."Expected Capacity Need";
        "WIP Item" := PlanningRoutingLine."WIP Item";
    end;

    [Scope('OnPrem')]
    procedure CopyFromRoutingLine(RoutingLine: Record "Routing Line")
    begin
        "Operation No." := RoutingLine."Operation No.";
        "Next Operation No." := RoutingLine."Next Operation No.";
        "Previous Operation No." := RoutingLine."Previous Operation No.";
        Type := RoutingLine.Type;
        "No." := RoutingLine."No.";
        "Work Center No." := RoutingLine."Work Center No.";
        "Work Center Group Code" := RoutingLine."Work Center Group Code";
        Description := RoutingLine.Description;
        "Setup Time" := RoutingLine."Setup Time";
        "Run Time" := RoutingLine."Run Time";
        "Wait Time" := RoutingLine."Wait Time";
        "Move Time" := RoutingLine."Move Time";
        "Fixed Scrap Quantity" := RoutingLine."Fixed Scrap Quantity";
        "Lot Size" := RoutingLine."Lot Size";
        "Scrap Factor %" := RoutingLine."Scrap Factor %";
        "Minimum Process Time" := RoutingLine."Minimum Process Time";
        "Maximum Process Time" := RoutingLine."Maximum Process Time";
        "Concurrent Capacities" := RoutingLine."Concurrent Capacities";
        if "Concurrent Capacities" = 0 then
            "Concurrent Capacities" := 1;
        "Send-Ahead Quantity" := RoutingLine."Send-Ahead Quantity";
        "Setup Time Unit of Meas. Code" := RoutingLine."Setup Time Unit of Meas. Code";
        "Run Time Unit of Meas. Code" := RoutingLine."Run Time Unit of Meas. Code";
        "Wait Time Unit of Meas. Code" := RoutingLine."Wait Time Unit of Meas. Code";
        "Move Time Unit of Meas. Code" := RoutingLine."Move Time Unit of Meas. Code";
        "Routing Link Code" := RoutingLine."Routing Link Code";
        "Standard Task Code" := RoutingLine."Standard Task Code";
        "Sequence No. (Forward)" := RoutingLine."Sequence No. (Forward)";
        "Sequence No. (Backward)" := RoutingLine."Sequence No. (Backward)";
        "Fixed Scrap Qty. (Accum.)" := RoutingLine."Fixed Scrap Qty. (Accum.)";
        "Scrap Factor % (Accumulated)" := RoutingLine."Scrap Factor % (Accumulated)";
        "Unit Cost per" := RoutingLine."Unit Cost per";
        FillDefaultLocationAndBins;

        OnAfterCopyFromRoutingLine(Rec, RoutingLine);
    end;

    local procedure DeleteRelations()
    begin
        OnBeforeDeleteRelations(Rec);

        ProdOrderRoutTool.SetRange(Status, Status);
        ProdOrderRoutTool.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderRoutTool.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderRoutTool.SetRange("Routing No.", "Routing No.");
        ProdOrderRoutTool.SetRange("Operation No.", "Operation No.");
        ProdOrderRoutTool.DeleteAll;

        ProdOrderRtngPersonnel.SetRange(Status, Status);
        ProdOrderRtngPersonnel.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderRtngPersonnel.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderRtngPersonnel.SetRange("Routing No.", "Routing No.");
        ProdOrderRtngPersonnel.SetRange("Operation No.", "Operation No.");
        ProdOrderRtngPersonnel.DeleteAll;

        ProdOrderRtngQltyMeas.SetRange(Status, Status);
        ProdOrderRtngQltyMeas.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderRtngQltyMeas.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderRtngQltyMeas.SetRange("Routing No.", "Routing No.");
        ProdOrderRtngQltyMeas.SetRange("Operation No.", "Operation No.");
        ProdOrderRtngQltyMeas.DeleteAll;

        ProdOrderRtngComment.SetRange(Status, Status);
        ProdOrderRtngComment.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderRtngComment.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderRtngComment.SetRange("Routing No.", "Routing No.");
        ProdOrderRtngComment.SetRange("Operation No.", "Operation No.");
        ProdOrderRtngComment.DeleteAll;

        ProdOrderCapNeed.SetRange(Status, Status);
        ProdOrderCapNeed.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderCapNeed.SetRange("Routing No.", "Routing No.");
        ProdOrderCapNeed.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderCapNeed.SetRange("Operation No.", "Operation No.");
        ProdOrderCapNeed.DeleteAll;

        OnAfterDeleteRelations(Rec, SkipUpdateOfCompBinCodes);
    end;

    local procedure WorkCenterTransferFields()
    begin
        "Work Center No." := WorkCenter."No.";
        "Work Center Group Code" := WorkCenter."Work Center Group Code";
        "Setup Time Unit of Meas. Code" := WorkCenter."Unit of Measure Code";
        "Run Time Unit of Meas. Code" := WorkCenter."Unit of Measure Code";
        "Wait Time Unit of Meas. Code" := WorkCenter."Unit of Measure Code";
        "Move Time Unit of Meas. Code" := WorkCenter."Unit of Measure Code";
        Description := WorkCenter.Name;
        "Flushing Method" := WorkCenter."Flushing Method";
        "Unit Cost per" := WorkCenter."Unit Cost";
        "Direct Unit Cost" := WorkCenter."Direct Unit Cost";
        "Indirect Cost %" := WorkCenter."Indirect Cost %";
        "Overhead Rate" := WorkCenter."Overhead Rate";
        "Unit Cost Calculation" := WorkCenter."Unit Cost Calculation";
        FillDefaultLocationAndBins;
        GetSubcPricelist;
        OnAfterWorkCenterTransferFields(Rec, WorkCenter);
    end;

    local procedure MachineCtrTransferFields()
    begin
        WorkCenter.Get(MachineCenter."Work Center No.");
        WorkCenterTransferFields;

        Description := MachineCenter.Name;
        "Setup Time" := MachineCenter."Setup Time";
        "Wait Time" := MachineCenter."Wait Time";
        "Move Time" := MachineCenter."Move Time";
        "Fixed Scrap Quantity" := MachineCenter."Fixed Scrap Quantity";
        "Scrap Factor %" := MachineCenter."Scrap %";
        "Minimum Process Time" := MachineCenter."Minimum Process Time";
        "Maximum Process Time" := MachineCenter."Maximum Process Time";
        "Concurrent Capacities" := MachineCenter."Concurrent Capacities";
        if "Concurrent Capacities" = 0 then
            "Concurrent Capacities" := 1;
        "Send-Ahead Quantity" := MachineCenter."Send-Ahead Quantity";
        "Setup Time Unit of Meas. Code" := MachineCenter."Setup Time Unit of Meas. Code";
        "Wait Time Unit of Meas. Code" := MachineCenter."Wait Time Unit of Meas. Code";
        "Move Time Unit of Meas. Code" := MachineCenter."Move Time Unit of Meas. Code";
        "Flushing Method" := MachineCenter."Flushing Method";
        "Unit Cost per" := MachineCenter."Unit Cost";
        "Direct Unit Cost" := MachineCenter."Direct Unit Cost";
        "Indirect Cost %" := MachineCenter."Indirect Cost %";
        "Overhead Rate" := MachineCenter."Overhead Rate";
        FillDefaultLocationAndBins;
        OnAfterMachineCtrTransferFields(Rec, WorkCenter, MachineCenter);
    end;

    procedure FillDefaultLocationAndBins()
    begin
        OnBeforeFillDefaultLocationAndBins(Rec);

        GetLine;
        "Location Code" := ProdOrderLine."Location Code";
        case Type of
            Type::"Work Center":
                begin
                    if WorkCenter."No." <> "No." then
                        WorkCenter.Get("No.");
                    if WorkCenter."Location Code" = "Location Code" then begin
                        "Open Shop Floor Bin Code" := WorkCenter."Open Shop Floor Bin Code";
                        "To-Production Bin Code" := WorkCenter."To-Production Bin Code";
                        "From-Production Bin Code" := WorkCenter."From-Production Bin Code";
                    end;
                end;
            Type::"Machine Center":
                begin
                    if MachineCenter."No." <> "No." then
                        MachineCenter.Get("No.");
                    if MachineCenter."Location Code" = "Location Code" then begin
                        "Open Shop Floor Bin Code" := MachineCenter."Open Shop Floor Bin Code";
                        "To-Production Bin Code" := MachineCenter."To-Production Bin Code";
                        "From-Production Bin Code" := MachineCenter."From-Production Bin Code";
                    end;
                    if WorkCenter."No." <> MachineCenter."Work Center No." then
                        WorkCenter.Get(MachineCenter."Work Center No.");
                    if WorkCenter."Location Code" = "Location Code" then begin
                        if "Open Shop Floor Bin Code" = '' then
                            "Open Shop Floor Bin Code" := WorkCenter."Open Shop Floor Bin Code";
                        if "To-Production Bin Code" = '' then
                            "To-Production Bin Code" := WorkCenter."To-Production Bin Code";
                        if "From-Production Bin Code" = '' then
                            "From-Production Bin Code" := WorkCenter."From-Production Bin Code";
                    end;
                end;
        end;

        OnAfterFillDefaultLocationAndBins(Rec);
    end;

    procedure CalcStartingEndingDates(Direction1: Option Forward,Backward)
    var
        ReservationCheckDateConfl: Codeunit "Reservation-Check Date Confl.";
    begin
        OnBeforeCalcStartingEndingDates(Rec, Direction1);

        if "Routing Status" = "Routing Status"::Finished then
            FieldError("Routing Status");

        Modify(true);

        ProdOrderRtngLine.Get(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.");

        ProdOrderRouteMgt.CalcSequenceFromActual(ProdOrderRtngLine, Direction1);
        ProdOrderRtngLine.Get(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.");
        ProdOrderRtngLine.SetCurrentKey(
          Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Sequence No. (Actual)");
        CalcProdOrder.CalculateRoutingFromActual(ProdOrderRtngLine, Direction1, false);

        CalculateRoutingBack;
        CalculateRoutingForward;

        Get(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.");
        GetLine;

        if Direction1 = Direction1::Forward then
            ShiftTimeForwardOnParentProdOrderLines(ProdOrderLine);

        ReservationCheckDateConfl.ProdOrderLineCheck(ProdOrderLine, true);

        OnAfterCalcStartingEndingDates(Rec, xRec, ProdOrderLine, CurrFieldNo);
    end;

    procedure SetRecalcStatus()
    begin
        Recalculate := true;

        OnAfterSetRecalcStatus(Rec, ProdOrderLine);
    end;

    procedure RunTimePer(): Decimal
    begin
        if "Lot Size" = 0 then
            "Lot Size" := 1;

        exit("Run Time" / "Lot Size");
    end;

    local procedure CalculateRoutingBack()
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
    begin
        if "Previous Operation No." <> '' then begin
            ProdOrderRtngLine.SetRange(Status, Status);
            ProdOrderRtngLine.SetRange("Prod. Order No.", "Prod. Order No.");
            ProdOrderRtngLine.SetRange("Routing Reference No.", "Routing Reference No.");
            ProdOrderRtngLine.SetRange("Routing No.", "Routing No.");
            ProdOrderRtngLine.SetFilter("Operation No.", "Previous Operation No.");
            ProdOrderRtngLine.SetFilter("Routing Status", '<>%1', ProdOrderRtngLine."Routing Status"::Finished);

            if ProdOrderRtngLine.Find('-') then
                repeat
                    ProdOrderRtngLine.SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.",
                      "Routing No.", "Sequence No. (Actual)");
                    WorkCenter.Get(ProdOrderRtngLine."Work Center No.");
                    case WorkCenter."Simulation Type" of
                        WorkCenter."Simulation Type"::Moves:
                            begin
                                ProdOrderRouteMgt.CalcSequenceFromActual(ProdOrderRtngLine, Direction::Backward);
                                CalcProdOrder.CalculateRoutingFromActual(ProdOrderRtngLine, Direction::Backward, true);
                            end;
                        WorkCenter."Simulation Type"::"Moves When Necessary":
                            if (ProdOrderRtngLine."Ending Date" > "Starting Date") or
                               ((ProdOrderRtngLine."Ending Date" = "Starting Date") and
                                (ProdOrderRtngLine."Ending Time" > "Starting Time"))
                            then begin
                                ProdOrderRouteMgt.CalcSequenceFromActual(ProdOrderRtngLine, Direction::Backward);
                                CalcProdOrder.CalculateRoutingFromActual(ProdOrderRtngLine, Direction::Backward, true);
                            end;
                        WorkCenter."Simulation Type"::Critical:
                            begin
                                if (ProdOrderRtngLine."Ending Date" > "Starting Date") or
                                   ((ProdOrderRtngLine."Ending Date" = "Starting Date") and
                                    (ProdOrderRtngLine."Ending Time" > "Starting Time"))
                                then
                                    Error(Text002);
                            end;
                    end;
                    ProdOrderRtngLine.SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.",
                      "Routing No.", "Operation No.");
                until ProdOrderRtngLine.Next = 0;
        end;

        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderLine.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderLine.SetRange("Routing No.", "Routing No.");
        if ProdOrderLine.Find('-') then
            repeat
                CalcProdOrder.CalculateProdOrderDates(ProdOrderLine, true);
                AdjustComponents(ProdOrderLine);
            until ProdOrderLine.Next = 0;
    end;

    local procedure CalculateRoutingForward()
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
    begin
        if "Next Operation No." <> '' then begin
            ProdOrderRtngLine.SetRange(Status, Status);
            ProdOrderRtngLine.SetRange("Prod. Order No.", "Prod. Order No.");
            ProdOrderRtngLine.SetRange("Routing Reference No.", "Routing Reference No.");
            ProdOrderRtngLine.SetRange("Routing No.", "Routing No.");
            ProdOrderRtngLine.SetFilter("Operation No.", "Next Operation No.");
            ProdOrderRtngLine.SetFilter("Routing Status", '<>%1', ProdOrderRtngLine."Routing Status"::Finished);

            if ProdOrderRtngLine.Find('-') then
                repeat
                    ProdOrderRtngLine.SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.",
                      "Routing No.", "Sequence No. (Actual)");
                    WorkCenter.Get(ProdOrderRtngLine."Work Center No.");
                    case WorkCenter."Simulation Type" of
                        WorkCenter."Simulation Type"::Moves:
                            begin
                                ProdOrderRouteMgt.CalcSequenceFromActual(ProdOrderRtngLine, Direction::Forward);
                                CalcProdOrder.CalculateRoutingFromActual(ProdOrderRtngLine, Direction::Forward, true);
                            end;
                        WorkCenter."Simulation Type"::"Moves When Necessary":
                            if (ProdOrderRtngLine."Starting Date" < "Ending Date") or
                               ((ProdOrderRtngLine."Starting Date" = "Ending Date") and
                                (ProdOrderRtngLine."Starting Time" < "Ending Time"))
                            then begin
                                ProdOrderRouteMgt.CalcSequenceFromActual(ProdOrderRtngLine, Direction::Forward);
                                CalcProdOrder.CalculateRoutingFromActual(ProdOrderRtngLine, Direction::Forward, true);
                            end;
                        WorkCenter."Simulation Type"::Critical:
                            begin
                                if (ProdOrderRtngLine."Starting Date" < "Ending Date") or
                                   ((ProdOrderRtngLine."Starting Date" = "Ending Date") and
                                    (ProdOrderRtngLine."Starting Time" < "Ending Time"))
                                then
                                    Error(Text003);
                            end;
                    end;
                    ProdOrderRtngLine.SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.",
                      "Routing No.", "Operation No.");
                until ProdOrderRtngLine.Next = 0;
        end;

        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderLine.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderLine.SetRange("Routing No.", "Routing No.");
        if ProdOrderLine.Find('-') then
            repeat
                CalcProdOrder.CalculateProdOrderDates(ProdOrderLine, true);
                AdjustComponents(ProdOrderLine);
            until ProdOrderLine.Next = 0;
        CalcProdOrder.CalculateComponents;
    end;

    local procedure ModifyCapNeedEntries()
    begin
        ProdOrderCapNeed.SetRange(Status, Status);
        ProdOrderCapNeed.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderCapNeed.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderCapNeed.SetRange("Routing No.", "Routing No.");
        ProdOrderCapNeed.SetRange("Operation No.", "Operation No.");
        ProdOrderCapNeed.SetRange("Requested Only", false);
        if ProdOrderCapNeed.Find('-') then
            repeat
                ProdOrderCapNeed."No." := "No.";
                ProdOrderCapNeed."Work Center No." := "Work Center No.";
                ProdOrderCapNeed."Work Center Group Code" := "Work Center Group Code";
                ProdOrderCapNeed.Modify;
            until ProdOrderCapNeed.Next = 0;
    end;

    local procedure AdjustComponents(var ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.SetRange(Status, Status);
        ProdOrderComp.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");

        if ProdOrderComp.Find('-') then
            repeat
                ProdOrderComp.Validate("Routing Link Code");
                ProdOrderComp.Modify;
            until ProdOrderComp.Next = 0;
    end;

    procedure UpdateDatetime()
    begin
        if ("Starting Date" <> 0D) and ("Starting Time" <> 0T) then
            "Starting Date-Time" := CreateDateTime("Starting Date", "Starting Time")
        else
            "Starting Date-Time" := 0DT;

        if ("Ending Date" <> 0D) and ("Ending Time" <> 0T) then
            "Ending Date-Time" := CreateDateTime("Ending Date", "Ending Time")
        else
            "Ending Date-Time" := 0DT;

        OnAfterUpdateDateTime(Rec, xRec, CurrFieldNo);
    end;

    procedure CheckPreviousAndNext()
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        TempDeletedProdOrderRtngLine: Record "Prod. Order Routing Line" temporary;
        TempRemainingProdOrderRtngLine: Record "Prod. Order Routing Line" temporary;
        ProdOrderRoutingForm: Page "Prod. Order Routing";
        ErrorOnNext: Boolean;
        ErrorOnPrevious: Boolean;
    begin
        if IsSerial then
            SetPreviousAndNext
        else begin
            TempDeletedProdOrderRtngLine := Rec;
            TempDeletedProdOrderRtngLine.Insert;

            ProdOrderRtngLine.SetRange(Status, Status);
            ProdOrderRtngLine.SetRange("Prod. Order No.", "Prod. Order No.");
            ProdOrderRtngLine.SetRange("Routing Reference No.", "Routing Reference No.");
            ProdOrderRtngLine.SetRange("Routing No.", "Routing No.");
            ProdOrderRtngLine.SetFilter("Operation No.", '<>%1', "Operation No.");
            ProdOrderRtngLine.SetFilter("Routing Status", '<>%1', ProdOrderRtngLine."Routing Status"::Finished);

            if ProdOrderRtngLine.Find('-') then
                repeat
                    if ProdOrderRtngLine."Next Operation No." <> '' then begin
                        TempDeletedProdOrderRtngLine.SetFilter("Operation No.", ProdOrderRtngLine."Next Operation No.");
                        ErrorOnNext := TempDeletedProdOrderRtngLine.FindFirst;
                    end else
                        ErrorOnNext := false;

                    if ProdOrderRtngLine."Previous Operation No." <> '' then begin
                        TempDeletedProdOrderRtngLine.SetFilter("Operation No.", ProdOrderRtngLine."Previous Operation No.");
                        ErrorOnPrevious := TempDeletedProdOrderRtngLine.FindFirst;
                    end else
                        ErrorOnPrevious := false;

                    if ErrorOnNext or ErrorOnPrevious then begin
                        TempRemainingProdOrderRtngLine := ProdOrderRtngLine;
                        TempRemainingProdOrderRtngLine.Insert;
                    end
                until ProdOrderRtngLine.Next = 0;

            if TempRemainingProdOrderRtngLine.Find('-') then begin
                Commit;
                if not Confirm(
                     StrSubstNo(Text004, FieldCaption("Next Operation No."), FieldCaption("Previous Operation No.")),
                     true)
                then
                    exit;
                ProdOrderRoutingForm.Initialize(StrSubstNo(Text005, "Operation No."));
                repeat
                    TempRemainingProdOrderRtngLine.Mark(true);
                until TempRemainingProdOrderRtngLine.Next = 0;
                TempRemainingProdOrderRtngLine.MarkedOnly(true);
                ProdOrderRoutingForm.SetTableView(TempRemainingProdOrderRtngLine);
                ProdOrderRoutingForm.RunModal;
            end;
        end;
    end;

    local procedure SetPreviousAndNext()
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
    begin
        if ProdOrderRtngLine.Get(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Previous Operation No.") then begin
            ProdOrderRtngLine."Next Operation No." := "Next Operation No.";
            ProdOrderRtngLine.Modify;
        end;
        if ProdOrderRtngLine.Get(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Next Operation No.") then begin
            ProdOrderRtngLine."Previous Operation No." := "Previous Operation No.";
            ProdOrderRtngLine.Modify;
        end;
    end;

    procedure SetNextOperations(var RtngLine: Record "Prod. Order Routing Line")
    var
        RtngLine2: Record "Prod. Order Routing Line";
    begin
        RtngLine2.SetRange(Status, RtngLine.Status);
        RtngLine2.SetRange("Prod. Order No.", RtngLine."Prod. Order No.");
        RtngLine2.SetRange("Routing Reference No.", RtngLine."Routing Reference No.");
        RtngLine2.SetRange("Routing No.", RtngLine."Routing No.");
        RtngLine2.SetFilter("Operation No.", '>%1', RtngLine."Operation No.");

        if RtngLine2.FindFirst then
            RtngLine."Next Operation No." := RtngLine2."Operation No."
        else begin
            RtngLine2.SetFilter("Operation No.", '');
            RtngLine2.SetRange("Next Operation No.", '');
            if RtngLine2.FindFirst then begin
                RtngLine2."Next Operation No." := RtngLine."Operation No.";
                RtngLine2.Modify;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetSubcPricelist()
    var
        SubcontractorPriceS: Record "Subcontractor Prices";
        SubcontractingPriceMgt: Codeunit SubcontractingPricesMgt;
    begin
        if (Type = Type::"Work Center") and (WorkCenter."Subcontractor No." <> '') then begin
            GetLine;
            SubcontractorPriceS."Vendor No." := WorkCenter."Subcontractor No.";
            SubcontractorPriceS."Item No." := ProdOrderLine."Item No.";
            SubcontractorPriceS."Standard Task Code" := "Standard Task Code";
            SubcontractorPriceS."Work Center No." := WorkCenter."No.";
            SubcontractorPriceS."Variant Code" := ProdOrderLine."Variant Code";
            SubcontractorPriceS."Unit of Measure Code" := ProdOrderLine."Unit of Measure Code";
            SubcontractorPriceS."Start Date" := WorkDate;
            SubcontractorPriceS."Currency Code" := '';
            SubcontractingPriceMgt.RoutingPricelistCost(
              SubcontractorPriceS,
              WorkCenter,
              "Direct Unit Cost",
              "Indirect Cost %",
              "Overhead Rate",
              "Unit Cost per",
              "Unit Cost Calculation",
              ProdOrderLine.Quantity,
              ProdOrderLine."Qty. per Unit of Measure",
              ProdOrderLine."Quantity (Base)");
        end;
    end;

    local procedure SubcontractPurchOrderExist(): Boolean
    begin
        if Status <> Status::Released then
            exit(false);

        ProdOrderLine.Reset;
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderLine.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderLine.SetRange("Routing No.", "Routing No.");
        if ProdOrderLine.Find('-') then
            repeat
                PurchLine.SetCurrentKey(
                  "Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
                PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
                PurchLine.SetRange(Type, PurchLine.Type::Item);
                PurchLine.SetRange("Prod. Order No.", "Prod. Order No.");
                PurchLine.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
                PurchLine.SetRange("Operation No.", "Operation No.");
                if not PurchLine.IsEmpty then
                    exit(true);
            until ProdOrderLine.Next = 0;

        exit(false);
    end;

    procedure UpdateComponentsBin(FromTrigger: Option Insert,Modify,Delete)
    var
        TempProdOrderRtngLine: Record "Prod. Order Routing Line" temporary;
    begin
        if SkipUpdateOfCompBinCodes then
            exit;

        if not UpdateOfComponentsBinRequired(FromTrigger) then
            exit;

        PopulateNewRoutingLineSet(TempProdOrderRtngLine, FromTrigger);
        ProdOrderRouteMgt.UpdateComponentsBin(TempProdOrderRtngLine, false);
    end;

    local procedure UpdateOfComponentsBinRequired(FromTrigger: Option Insert,Modify,Delete): Boolean
    begin
        if ("No." = '') and (xRec."No." = "No.") then // bin codes are and were empty
            exit(false);

        case FromTrigger of
            FromTrigger::Insert, FromTrigger::Delete:
                exit(("Previous Operation No." = '') or ("Routing Link Code" <> ''));
            FromTrigger::Modify:
                exit(
                  ((xRec."Previous Operation No." = '') and ("Previous Operation No." <> '')) or
                  ((xRec."Previous Operation No." <> '') and ("Previous Operation No." = '')) or
                  (xRec."Routing Link Code" <> "Routing Link Code") or
                  ((("Previous Operation No." = '') or ("Routing Link Code" <> '')) and
                   ((xRec."To-Production Bin Code" <> "To-Production Bin Code") or
                    (xRec."Open Shop Floor Bin Code" <> "Open Shop Floor Bin Code"))));
        end;
    end;

    local procedure PopulateNewRoutingLineSet(var ProdOrderRtngLineTmp: Record "Prod. Order Routing Line"; FromTrigger: Option Insert,Modify,Delete)
    var
        ProdOrderRtngLine2: Record "Prod. Order Routing Line";
    begin
        // copy existing routings for this prod. order to temporary table
        ProdOrderRtngLineTmp.DeleteAll;
        ProdOrderRtngLine2.SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.");
        ProdOrderRtngLine2.SetRange(Status, Status);
        ProdOrderRtngLine2.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderRtngLine2.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderRtngLine2.SetRange("Routing No.", "Routing No.");
        if ProdOrderRtngLine2.FindSet(false) then
            repeat
                ProdOrderRtngLineTmp := ProdOrderRtngLine2;
                ProdOrderRtngLineTmp.Insert;
            until ProdOrderRtngLine2.Next = 0;

        // update the recordset with the current change
        ProdOrderRtngLineTmp := Rec;
        case FromTrigger of
            FromTrigger::Insert:
                ProdOrderRtngLineTmp.Insert;
            FromTrigger::Modify:
                ProdOrderRtngLineTmp.Modify;
            FromTrigger::Delete:
                ProdOrderRtngLineTmp.Delete;
        end;
    end;

    procedure SetSkipUpdateOfCompBinCodes(Setting: Boolean)
    begin
        SkipUpdateOfCompBinCodes := Setting;
    end;

    local procedure ShiftTimeForwardOnParentProdOrderLines(var ChildProdOrderLine: Record "Prod. Order Line")
    var
        ParentProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ParentProdOrderLine.SetRange(Status, ChildProdOrderLine.Status);
        ParentProdOrderLine.SetRange("Prod. Order No.", ChildProdOrderLine."Prod. Order No.");
        ParentProdOrderLine.SetRange("Planning Level Code", ChildProdOrderLine."Planning Level Code" - 1);
        ParentProdOrderLine.SetFilter("Starting Date-Time", '<%1', ChildProdOrderLine."Ending Date-Time");
        if ParentProdOrderLine.FindSet then
            repeat
                ProdOrderComponent.SetRange(Status, ParentProdOrderLine.Status);
                ProdOrderComponent.SetRange("Prod. Order No.", ParentProdOrderLine."Prod. Order No.");
                ProdOrderComponent.SetRange("Prod. Order Line No.", ParentProdOrderLine."Line No.");
                ProdOrderComponent.SetRange("Supplied-by Line No.", ChildProdOrderLine."Line No.");
                if not ProdOrderComponent.IsEmpty then begin
                    if GuiAllowed then
                        ShowMessage(TimeShiftedOnParentLineMsg);
                    ParentProdOrderLine.Validate("Starting Date-Time", ChildProdOrderLine."Ending Date-Time");
                    if ParentProdOrderLine."Ending Date-Time" < ParentProdOrderLine."Starting Date-Time" then
                        ParentProdOrderLine."Ending Date-Time" := ParentProdOrderLine."Starting Date-Time";
                    ParentProdOrderLine.Modify(true);
                    ShiftTimeForwardOnParentProdOrderLines(ParentProdOrderLine);
                end;
            until ParentProdOrderLine.Next = 0;
    end;

    local procedure ShowMessage(MessageText: Text)
    begin
        TempErrorMessage.SetContext(Rec);
        if TempErrorMessage.FindRecord(RecordId, 0, TempErrorMessage."Message Type"::Warning, MessageText) = 0 then begin
            TempErrorMessage.LogMessage(Rec, 0, TempErrorMessage."Message Type"::Warning, MessageText);
            Message(MessageText);
        end;
    end;

    local procedure NoTerminationProcessesExist(): Boolean
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange(Status, Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Routing No.", "Routing No.");
        ProdOrderRoutingLine.SetRange("Next Operation No.", '');
        ProdOrderRoutingLine.SetFilter("Operation No.", '<>%1', "Operation No.");
        exit(ProdOrderRoutingLine.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure IsSerial(): Boolean
    begin
        GetLine;
        exit(ProdOrderLine."Routing Type" = ProdOrderLine."Routing Type"::Serial)
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcStartingEndingDates(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var xProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderLine: Record "Prod. Order Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; RoutingLine: Record "Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteRelations(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; SkipUpdateOfCompBinCodes: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillDefaultLocationAndBins(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWorkCenterTransferFields(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; WorkCenter: Record "Work Center")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMachineCtrTransferFields(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; WorkCenter: Record "Work Center"; MachineCenter: Record "Machine Center")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetRecalcStatus(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromStdTaskTool(var ProdOrderRoutingTool: Record "Prod. Order Routing Tool"; StandardTaskTool: Record "Standard Task Tool")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromStdTaskPersonnel(var ProdOrderRoutingPersonnel: Record "Prod. Order Routing Personnel"; StandardTaskPersonnel: Record "Standard Task Personnel")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromStdTaskQltyMeasure(var ProdOrderRtngQltyMeas: Record "Prod. Order Rtng Qlty Meas."; StandardTaskQualityMeasure: Record "Standard Task Quality Measure")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromStdTaskComment(var ProdOrderRtngCommentLine: Record "Prod. Order Rtng Comment Line"; StandardTaskDescription: Record "Standard Task Description")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDateTime(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var xProdOrderRoutingLine: Record "Prod. Order Routing Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateNo(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var xProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcStartingEndingDates(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; Direction: Option Forward,Backward)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteRelations(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillDefaultLocationAndBins(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTerminationProcessesErr(var IsHandled: Boolean)
    begin
    end;
}

