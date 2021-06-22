report 5300 "Outlook Synch. Change Log Set."
{
    Caption = 'Outlook Synch. Change Log Set.';
    ProcessingOnly = true;

    dataset
    {
        dataitem(OSynchEntity; "Outlook Synch. Entity")
        {
            DataItemTableView = SORTING(Code);
            RequestFilterFields = "Code";
            dataitem(OSynchEntityElement; "Outlook Synch. Entity Element")
            {
                DataItemLink = "Synch. Entity Code" = FIELD(Code);
                DataItemTableView = SORTING("Synch. Entity Code", "Element No.") ORDER(Ascending) WHERE("Element No." = FILTER(<> 0));
                dataitem(OSynchFilterElement; "Outlook Synch. Filter")
                {
                    DataItemLink = "Record GUID" = FIELD("Record GUID");
                    DataItemTableView = SORTING("Record GUID", "Filter Type", "Line No.") ORDER(Ascending) WHERE("Filter Type" = CONST("Table Relation"));

                    trigger OnAfterGetRecord()
                    begin
                        RegisterChangeLogFilter(OSynchFilterElement);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    RegisterChangeLogPrimaryKey("Table No.");
                end;
            }
            dataitem(OSynchField; "Outlook Synch. Field")
            {
                DataItemLink = "Synch. Entity Code" = FIELD(Code);
                DataItemTableView = SORTING("Synch. Entity Code", "Element No.", "Line No.");

                trigger OnAfterGetRecord()
                var
                    OSynchFilter: Record "Outlook Synch. Filter";
                    OSynchEntityElement: Record "Outlook Synch. Entity Element";
                begin
                    if "Table No." <> 0 then begin
                        OSynchFilter.Reset();
                        OSynchFilter.SetRange("Record GUID", "Record GUID");
                        OSynchFilter.SetRange("Filter Type", OSynchFilter."Filter Type"::"Table Relation");
                        OSynchFilter.SetRange(Type, OSynchFilter.Type::FIELD);
                        if not OSynchFilter.FindFirst then begin
                            CalcFields("Table Caption");
                            if "Element No." = 0 then
                                Error(Text001, "Table Caption", OSynchEntity.TableCaption, OSynchEntity.Code);

                            OSynchEntityElement.Get("Synch. Entity Code", "Element No.");
                            OSynchEntityElement.CalcFields("Table Caption");
                            Error(
                              Text005,
                              "Table Caption",
                              OSynchEntityElement."Table Caption",
                              OSynchEntityElement."Outlook Collection",
                              OSynchEntity.Code);
                        end;

                        if TypeHelper.GetField("Table No.", "Field No.", Field) then begin
                            Field.TestField(Enabled, true);
                            RegisterChangeLogField("Table No.", "Field No.");
                        end;

                        FieldID := OSynchFilter."Master Table Field No.";
                    end else
                        FieldID := "Field No.";

                    if TypeHelper.GetField("Master Table No.", FieldID, Field) then begin
                        Field.TestField(Enabled, true);
                        RegisterChangeLogField("Master Table No.", FieldID);
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                RegisterChangeLogPrimaryKey("Table No.");
            end;
        }
        dataitem(OSynchFilterEntity; "Outlook Synch. Filter")
        {
            DataItemLink = "Record GUID" = FIELD("Record GUID");
            DataItemLinkReference = OSynchEntity;
            DataItemTableView = SORTING("Record GUID", "Filter Type", "Line No.") ORDER(Ascending);

            trigger OnAfterGetRecord()
            begin
                RegisterChangeLogFilter(OSynchFilterEntity);
            end;
        }
        dataitem(OSynchUserSetup; "Outlook Synch. User Setup")
        {
            DataItemLink = "Synch. Entity Code" = FIELD(Code);
            DataItemLinkReference = OSynchEntity;
            DataItemTableView = SORTING("User ID", "Synch. Entity Code") ORDER(Ascending);
            dataitem(OSynchFilterUserSetup; "Outlook Synch. Filter")
            {
                DataItemLink = "Record GUID" = FIELD("Record GUID");
                DataItemTableView = SORTING("Record GUID", "Filter Type", "Line No.") ORDER(Ascending);

                trigger OnAfterGetRecord()
                begin
                    RegisterChangeLogFilter(OSynchFilterUserSetup);
                end;
            }
        }
        dataitem(OSynchDependency; "Outlook Synch. Dependency")
        {
            DataItemLink = "Synch. Entity Code" = FIELD(Code);
            DataItemLinkReference = OSynchEntity;
            DataItemTableView = SORTING("Synch. Entity Code", "Element No.", "Depend. Synch. Entity Code") ORDER(Ascending);
            dataitem(OSynchFilterDependency; "Outlook Synch. Filter")
            {
                DataItemLink = "Record GUID" = FIELD("Record GUID");
                DataItemTableView = SORTING("Record GUID", "Filter Type", "Line No.") ORDER(Ascending);

                trigger OnAfterGetRecord()
                begin
                    RegisterChangeLogFilter(OSynchFilterDependency);
                end;
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        ChangeLogSetup: Record "Change Log Setup";
    begin
        if not ChangeLogSetup.Get then
            ChangeLogSetup.Insert();
        if not ChangeLogSetup."Change Log Activated" then begin
            ChangeLogSetup."Change Log Activated" := true;
            ChangeLogSetup.Modify();
            Message(Text002);
        end else
            Message(Text003);
    end;

    trigger OnPreReport()
    begin
        if not OSynchEntity.FindFirst then
            Error(Text004);
    end;

    var
        "Field": Record "Field";
        TypeHelper: Codeunit "Type Helper";
        FieldID: Integer;
        Text001: Label 'The relation between the %1 table and %2 table in the %3 entity cannot be determined. Please verify your synchronization settings for this entity.';
        Text002: Label 'The change log settings have been registered successfully. You must close and reopen the company for the new change log settings to take effect.';
        Text003: Label 'The change log settings have been registered successfully.';
        Text004: Label 'The entity cannot be found. Make sure that you have typed its name correctly.';
        Text005: Label 'The relation between the %1 table and %2 table in the %3 collection from the %4 entity cannot be determined. Verify your synchronization settings for this entity.';

    local procedure RegisterChangeLogField(TableID: Integer; FieldID: Integer)
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
        ChangeLogSetupField: Record "Change Log Setup (Field)";
        NeedToBeUpdated: Boolean;
    begin
        with ChangeLogSetupTable do begin
            Reset;
            if not Get(TableID) then begin
                Init;
                "Table No." := TableID;
                Validate("Log Insertion", "Log Insertion"::"Some Fields");
                Validate("Log Modification", "Log Modification"::"Some Fields");
                Validate("Log Deletion", "Log Modification"::"Some Fields");
                Insert;
                NeedToBeUpdated := true;
            end else begin
                NeedToBeUpdated :=
                  ("Log Insertion" <> "Log Insertion"::"All Fields") or
                  ("Log Modification" <> "Log Modification"::"All Fields") or
                  ("Log Deletion" <> "Log Deletion"::"All Fields");

                if "Log Insertion" <> "Log Insertion"::"All Fields" then
                    "Log Insertion" := "Log Insertion"::"Some Fields";

                if "Log Modification" <> "Log Modification"::"All Fields" then
                    "Log Modification" := "Log Insertion"::"Some Fields";

                if "Log Deletion" <> "Log Deletion"::"All Fields" then
                    "Log Deletion" := "Log Deletion"::"Some Fields";

                if NeedToBeUpdated then
                    Modify;
            end;
        end;

        if not NeedToBeUpdated then
            exit;

        with ChangeLogSetupField do begin
            Reset;
            if not Get(TableID, FieldID) then begin
                Init;
                "Table No." := TableID;
                "Field No." := FieldID;
                "Log Insertion" := true;
                "Log Modification" := true;
                "Log Deletion" := true;
                Insert;
            end else begin
                "Log Insertion" := true;
                "Log Modification" := true;
                "Log Deletion" := true;
                Modify;
            end;
        end;
    end;

    local procedure RegisterChangeLogPrimaryKey(TableID: Integer)
    var
        RecRef: RecordRef;
        I: Integer;
    begin
        RecRef.Open(TableID, true);
        for I := 1 to RecRef.KeyIndex(1).FieldCount do
            RegisterChangeLogField(TableID, RecRef.KeyIndex(1).FieldIndex(I).Number);
        RecRef.Close;
    end;

    local procedure RegisterChangeLogFilter(OSynchFilter1: Record "Outlook Synch. Filter")
    begin
        if TypeHelper.GetField(OSynchFilter1."Table No.", OSynchFilter1."Field No.", Field) then begin
            Field.TestField(Enabled, true);
            RegisterChangeLogField(OSynchFilter1."Table No.", OSynchFilter1."Field No.");
        end;
        if TypeHelper.GetField(OSynchFilter1."Master Table No.", OSynchFilter1."Master Table Field No.", Field) then begin
            Field.TestField(Enabled, true);
            RegisterChangeLogField(OSynchFilter1."Master Table No.", OSynchFilter1."Master Table Field No.");
        end;
    end;
}

