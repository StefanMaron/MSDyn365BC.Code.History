table 31120 "EET Service Setup"
{
    Caption = 'EET Service Setup (Obsolete)';
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '18.0';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Service URL"; Text[250])
        {
            Caption = 'Service URL';
            ExtendedDatatype = URL;

            trigger OnValidate()
            var
                EETServiceMgt: Codeunit "EET Service Mgt.";
                Confirmed: Boolean;
            begin
                Confirmed := true;
                if "Service URL" <> xRec."Service URL" then
                    if GuiAllowed and AreEETEntriesToSending then
                        case "Service URL" of
                            EETServiceMgt.GetWebServiceURLTxt:
                                Confirmed := Confirm(ProductionEnvironmentQst, false);
                            EETServiceMgt.GetWebServicePlayGroundURLTxt:
                                Confirmed := Confirm(NonproductionEnvironmentQst, false);
                        end;

                if not Confirmed then
                    "Service URL" := xRec."Service URL";
            end;
        }
        field(10; "Sales Regime"; Option)
        {
            Caption = 'Sales Regime';
            OptionCaption = 'Regular,Simplified';
            OptionMembers = Regular,Simplified;
        }
        field(11; "Limit Response Time"; Integer)
        {
            Caption = 'Limit Response Time';
            InitValue = 2000;
            MinValue = 2000;
        }
        field(12; "Appointing VAT Reg. No."; Text[20])
        {
            Caption = 'Appointing VAT Reg. No.';
        }
        field(15; Enabled; Boolean)
        {
            Caption = 'Enabled';

            trigger OnValidate()
            begin
                if Enabled then begin
                    ScheduleJobQueueEntry;
                    if Confirm(JobQEntryCreatedQst) then
                        ShowJobQueueEntry;
                end else
                    CancelJobQueueEntry;
            end;
        }
        field(17; "Certificate Code"; Code[10])
        {
            Caption = 'Certificate Code';
            TableRelation = "Certificate CZ Code";
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField("Primary Key", '');
        SetURLToDefault(false);
    end;

    var
        JobQEntryCreatedQst: Label 'Job queue entry for sending electronic sales records has been created.\\Do you want to open the Job Queue Entries window?';
        ProductionEnvironmentQst: Label 'There are still unprocessed EET Entries.\Entering the URL of the production environment, these entries will be registered in a production environment!\\ Do you want to continue?';
        NonproductionEnvironmentQst: Label 'There are still unprocessed EET Entries.\Entering the URL of the non-production environment, these entries will be registered in a non-production environment!\\ Do you want to continue?';
        URLOptionsQst: Label '&Production environment URL,&Non-production environment URL';

    [Scope('OnPrem')]
    [Obsolete('Moved to Cash Desk Localization for Czech.', '18.0')]
    procedure SetURLToDefault(ShowDialog: Boolean)
    var
        EETServiceMgt: Codeunit "EET Service Mgt.";
        Selection: Integer;
    begin
        TestField(Enabled, false);

        if not ShowDialog then begin
            EETServiceMgt.SetURLToDefault(Rec);
            exit;
        end;

        Selection := 2;
        if GuiAllowed then
            Selection := StrMenu(URLOptionsQst, Selection);

        case Selection of
            1:
                Validate("Service URL", EETServiceMgt.GetWebServiceURLTxt);
            2:
                Validate("Service URL", EETServiceMgt.GetWebServicePlayGroundURLTxt);
            else
                exit;
        end;
    end;

    local procedure ScheduleJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
        DummyRecId: RecordID;
    begin
        JobQueueEntry.ScheduleRecurrentJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit,
          CODEUNIT::"EET Send Entries To Service", DummyRecId);
    end;

    local procedure CancelJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, CODEUNIT::"EET Send Entries To Service") then
            JobQueueEntry.Cancel;
    end;

    [Scope('OnPrem')]
    [Obsolete('Moved to Cash Desk Localization for Czech.', '18.0')]
    procedure ShowJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"EET Send Entries To Service");
        if JobQueueEntry.FindFirst then
            PAGE.Run(PAGE::"Job Queue Entries", JobQueueEntry);
    end;

    local procedure AreEETEntriesToSending(): Boolean
    var
        EETEntry: Record "EET Entry";
    begin
        EETEntry.SetFilter("EET Status", '%1|%2',
          EETEntry."EET Status"::Failure,
          EETEntry."EET Status"::"Send Pending");
        exit(not EETEntry.IsEmpty);
    end;
}

