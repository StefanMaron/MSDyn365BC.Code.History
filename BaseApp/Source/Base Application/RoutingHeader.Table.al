table 99000763 "Routing Header"
{
    Caption = 'Routing Header';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "Routing List";
    LookupPageID = "Routing List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                "Search Description" := Description;
            end;
        }
        field(3; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(4; "Search Description"; Code[100])
        {
            Caption = 'Search Description';
        }
        field(10; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(12; Comment; Boolean)
        {
            CalcFormula = Exist ("Manufacturing Comment Line" WHERE("Table Name" = CONST("Routing Header"),
                                                                    "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'New,Certified,Under Development,Closed';
            OptionMembers = New,Certified,"Under Development",Closed;

            trigger OnValidate()
            begin
                if (Status <> xRec.Status) and (Status = Status::Certified) then
                    CheckRouting.Calculate(Rec, '');

                if Status = Status::Closed then begin
                    if Confirm(
                         Text001, false)
                    then begin
                        RtngVersion.SetRange("Routing No.", "No.");
                        RtngVersion.ModifyAll(Status, RtngVersion.Status::Closed);
                    end else
                        Status := xRec.Status;
                end;
            end;
        }
        field(21; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Serial,Parallel';
            OptionMembers = Serial,Parallel;

            trigger OnValidate()
            begin
                if Status = Status::Certified then
                    FieldError(Status);
            end;
        }
        field(50; "Version Nos."; Code[20])
        {
            Caption = 'Version Nos.';
            TableRelation = "No. Series";
        }
        field(51; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Description")
        {
        }
        key(Key3; Description)
        {
        }
        key(Key4; Status)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, Status)
        {
        }
    }

    trigger OnDelete()
    var
        Item: Record Item;
        RtngLine: Record "Routing Line";
        MfgComment: Record "Manufacturing Comment Line";
    begin
        MfgComment.SetRange("Table Name", MfgComment."Table Name"::"Routing Header");
        MfgComment.SetRange("No.", "No.");
        MfgComment.DeleteAll();

        RtngLine.LockTable();
        RtngLine.SetRange("Routing No.", "No.");
        RtngLine.DeleteAll(true);

        RtngVersion.SetRange("Routing No.", "No.");
        RtngVersion.DeleteAll();

        Item.SetRange("Routing No.", "No.");
        if not Item.IsEmpty then
            Error(Text000);
    end;

    trigger OnInsert()
    begin
        MfgSetup.Get();
        if "No." = '' then begin
            MfgSetup.TestField("Routing Nos.");
            NoSeriesMgt.InitSeries(MfgSetup."Routing Nos.", xRec."No. Series", 0D, "No.", "No. Series");
        end;
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
    end;

    trigger OnRename()
    begin
        if Status = Status::Certified then
            Error(Text002, TableCaption, FieldCaption(Status), Format(Status));
    end;

    var
        Text000: Label 'This Routing is being used on Items.';
        Text001: Label 'All versions attached to the routing will be closed. Close routing?';
        MfgSetup: Record "Manufacturing Setup";
        RoutingHeader: Record "Routing Header";
        RtngVersion: Record "Routing Version";
        CheckRouting: Codeunit "Check Routing Lines";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        Text002: Label 'You cannot rename the %1 when %2 is %3.';

    procedure AssistEdit(OldRtngHeader: Record "Routing Header"): Boolean
    begin
        with RoutingHeader do begin
            RoutingHeader := Rec;
            MfgSetup.Get();
            MfgSetup.TestField("Routing Nos.");
            if NoSeriesMgt.SelectSeries(MfgSetup."Routing Nos.", OldRtngHeader."No. Series", "No. Series") then begin
                NoSeriesMgt.SetSeries("No.");
                Rec := RoutingHeader;
                exit(true);
            end;
        end;
    end;
}

