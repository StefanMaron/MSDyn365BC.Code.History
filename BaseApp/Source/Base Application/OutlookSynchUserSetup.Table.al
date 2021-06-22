table 5305 "Outlook Synch. User Setup"
{
    Caption = 'Outlook Synch. User Setup';
    PasteIsValid = false;
    ReplicateData = false;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("User ID");
            end;
        }
        field(2; "Synch. Entity Code"; Code[10])
        {
            Caption = 'Synch. Entity Code';
            NotBlank = true;
            TableRelation = "Outlook Synch. Entity".Code;

            trigger OnValidate()
            begin
                if "Synch. Entity Code" = xRec."Synch. Entity Code" then
                    exit;

                OSynchEntity.Get("Synch. Entity Code");
                OSynchEntity.TestField(Description);
                OSynchEntity.TestField("Table No.");
                OSynchEntity.TestField("Outlook Item");

                CalcFields(Description, "No. of Elements");
            end;
        }
        field(3; Description; Text[80])
        {
            CalcFormula = Lookup ("Outlook Synch. Entity".Description WHERE(Code = FIELD("Synch. Entity Code")));
            Caption = 'Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; Condition; Text[250])
        {
            Caption = 'Condition';
            Editable = false;
        }
        field(5; "Synch. Direction"; Option)
        {
            Caption = 'Synch. Direction';
            OptionCaption = 'Bidirectional,Microsoft Dynamics NAV to Outlook,Outlook to Microsoft Dynamics NAV';
            OptionMembers = Bidirectional,"Microsoft Dynamics NAV to Outlook","Outlook to Microsoft Dynamics NAV";

            trigger OnValidate()
            var
                OSynchDependency: Record "Outlook Synch. Dependency";
                RecRef: RecordRef;
                FldRef: FieldRef;
            begin
                if "Synch. Direction" = xRec."Synch. Direction" then
                    exit;

                if "Synch. Direction" = "Synch. Direction"::Bidirectional then
                    exit;

                CalcFields("No. of Elements");
                if "No. of Elements" <> 0 then begin
                    OSynchSetupDetail.Reset();
                    OSynchSetupDetail.SetRange("User ID", "User ID");
                    OSynchSetupDetail.SetRange("Synch. Entity Code", "Synch. Entity Code");
                    if OSynchSetupDetail.Find('-') then
                        repeat
                            OSynchEntityElement.Get(OSynchSetupDetail."Synch. Entity Code", OSynchSetupDetail."Element No.");
                            Modify;
                            OSynchEntityElement.CalcFields("No. of Dependencies");
                            if OSynchEntityElement."No. of Dependencies" > 0 then
                                if not OSynchSetupMgt.CheckOCollectionAvailability(OSynchEntityElement, "User ID") then
                                    "Synch. Direction" := xRec."Synch. Direction";
                        until OSynchSetupDetail.Next = 0;
                end;

                OSynchDependency.Reset();
                OSynchDependency.SetRange("Depend. Synch. Entity Code", "Synch. Entity Code");
                if OSynchDependency.Find('-') then
                    repeat
                        if OSynchUserSetup.Get("User ID", OSynchDependency."Synch. Entity Code") then
                            if OSynchSetupDetail.Get(
                                 OSynchUserSetup."User ID",
                                 OSynchUserSetup."Synch. Entity Code",
                                 OSynchDependency."Element No.")
                            then
                                if "Synch. Direction" <> OSynchUserSetup."Synch. Direction" then begin
                                    Clear(RecRef);
                                    Clear(FldRef);
                                    RecRef.GetTable(Rec);
                                    FldRef := RecRef.Field(FieldNo("Synch. Direction"));
                                    Error(
                                      Text001,
                                      FieldCaption("Synch. Direction"),
                                      SelectStr(OSynchUserSetup."Synch. Direction"::Bidirectional + 1, FldRef.OptionMembers),
                                      OSynchDependency."Synch. Entity Code");
                                end;
                    until OSynchDependency.Next = 0;
            end;
        }
        field(6; "Last Synch. Time"; DateTime)
        {
            Caption = 'Last Synch. Time';
        }
        field(7; "Record GUID"; Guid)
        {
            Caption = 'Record GUID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(8; "No. of Elements"; Integer)
        {
            CalcFormula = Count ("Outlook Synch. Setup Detail" WHERE("User ID" = FIELD("User ID"),
                                                                     "Synch. Entity Code" = FIELD("Synch. Entity Code"),
                                                                     "Outlook Collection" = FILTER(<> '')));
            Caption = 'No. of Elements';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "User ID", "Synch. Entity Code")
        {
            Clustered = true;
        }
        key(Key2; "Record GUID")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if not CheckSetupDetail(Rec) then
            Error('');

        OSynchSetupDetail.Reset();
        OSynchSetupDetail.SetRange("User ID", "User ID");
        OSynchSetupDetail.SetRange("Synch. Entity Code", "Synch. Entity Code");
        OSynchSetupDetail.DeleteAll();

        OSynchFilter.Reset();
        OSynchFilter.SetRange("Record GUID", "Record GUID");
        OSynchFilter.DeleteAll();
    end;

    trigger OnInsert()
    begin
        if IsNullGuid("Record GUID") then
            "Record GUID" := CreateGuid;
    end;

    trigger OnRename()
    begin
        if not CheckSetupDetail(xRec) then
            Error('');

        if xRec."Synch. Entity Code" = "Synch. Entity Code" then
            exit;

        Condition := '';
        "Synch. Direction" := "Synch. Direction"::Bidirectional;
        "Last Synch. Time" := 0DT;

        OSynchSetupDetail.Reset();
        OSynchSetupDetail.SetRange("User ID", "User ID");
        OSynchSetupDetail.SetRange("Synch. Entity Code", xRec."Synch. Entity Code");
        OSynchSetupDetail.DeleteAll();

        OSynchFilter.Reset();
        OSynchFilter.SetRange("Record GUID", "Record GUID");
        OSynchFilter.DeleteAll();
    end;

    var
        OSynchEntity: Record "Outlook Synch. Entity";
        OSynchEntityElement: Record "Outlook Synch. Entity Element";
        OSynchFilter: Record "Outlook Synch. Filter";
        OSynchUserSetup: Record "Outlook Synch. User Setup";
        OSynchSetupDetail: Record "Outlook Synch. Setup Detail";
        OSynchSetupMgt: Codeunit "Outlook Synch. Setup Mgt.";
        Text001: Label 'The value of the %1 field must either be %2 or match the synchronization direction of the %3 entity because these entities are dependent.';
        Text002: Label 'The %1 entity is used for the synchronization of one or more Outlook item collections.\If you delete this entity, all collections will be removed from synchronization. Do you want to proceed?';

    procedure CheckSetupDetail(OSynchUserSetup1: Record "Outlook Synch. User Setup"): Boolean
    var
        OSynchDependency: Record "Outlook Synch. Dependency";
    begin
        OSynchSetupDetail.Reset();
        OSynchSetupDetail.SetRange("User ID", OSynchUserSetup1."User ID");
        if OSynchSetupDetail.Find('-') then
            repeat
                if OSynchDependency.Get(
                     OSynchSetupDetail."Synch. Entity Code",
                     OSynchSetupDetail."Element No.",
                     OSynchUserSetup1."Synch. Entity Code")
                then
                    OSynchSetupDetail.Mark(true);
            until OSynchSetupDetail.Next = 0;

        OSynchSetupDetail.MarkedOnly(true);
        if OSynchSetupDetail.Count > 0 then begin
            if Confirm(Text002, false, OSynchUserSetup1."Synch. Entity Code") then begin
                OSynchSetupDetail.DeleteAll();
                exit(true);
            end;
            exit(false);
        end;
        exit(true);
    end;
}

