page 5311 "Outlook Synch. Dependencies"
{
    Caption = 'Outlook Synch. Dependencies';
    DataCaptionExpression = GetFormCaption;
    DataCaptionFields = "Synch. Entity Code";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Outlook Synch. Dependency";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Depend. Synch. Entity Code"; "Depend. Synch. Entity Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the synchronization entity. The program copies this code from the Code field of the Outlook Synch. Entity table.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a brief description of the entity which code is specified in the Description field of the Outlook Synch. Entity table.';
                }
                field(Condition; Condition)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the filter expression which is applied to the collection''s table defined by the Depend. Synch. Entity Code and Element No. fields. This condition is required when one collection search field relates to several different tables (the conditional table relation).';

                    trigger OnAssistEdit()
                    begin
                        if IsNullGuid("Record GUID") then
                            "Record GUID" := CreateGuid;

                        OSynchEntityElement.Get("Synch. Entity Code", "Element No.");
                        Condition :=
                          CopyStr(OSynchSetupMgt.ShowOSynchFiltersForm("Record GUID", OSynchEntityElement."Table No.", 0), 1, MaxStrLen(Condition));
                    end;
                }
                field("Table Relation"; "Table Relation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a filter expression. It is used to select the record from the table on which Dependent Synch. Entity is based.';

                    trigger OnAssistEdit()
                    begin
                        if IsNullGuid("Record GUID") then
                            "Record GUID" := CreateGuid;

                        OSynchEntity.Get("Depend. Synch. Entity Code");
                        OSynchEntityElement.Get("Synch. Entity Code", "Element No.");
                        "Table Relation" :=
                          CopyStr(
                            OSynchSetupMgt.ShowOSynchFiltersForm("Record GUID", OSynchEntity."Table No.", OSynchEntityElement."Table No."),
                            1, MaxStrLen(Condition));
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    var
        OSynchEntity: Record "Outlook Synch. Entity";
        OSynchEntityElement: Record "Outlook Synch. Entity Element";
        OSynchSetupMgt: Codeunit "Outlook Synch. Setup Mgt.";

    procedure GetFormCaption(): Text[80]
    begin
        exit(StrSubstNo('%1 %2 %3', OSynchEntityElement.TableCaption, "Synch. Entity Code", "Element No."));
    end;
}

