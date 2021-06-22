page 5301 "Outlook Synch. Entity Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Outlook Synch. Entity Element";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Table No."; "Table No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the Dynamics 365 table which corresponds to the Outlook item a collection of which is specified in the Outlook Collection field.';
                }
                field("Table Caption"; "Table Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the Dynamics 365 table to synchronize. The program fills in this field when you specify a table number in the Table No. field.';
                }
                field("Table Relation"; "Table Relation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a filter expression that defines which Dynamics 365 entries will be selected for synchronization. It is used to define relations between tables specified in the Table No. fields.';

                    trigger OnAssistEdit()
                    begin
                        CalcFields("Master Table No.");
                        if "Table No." <> 0 then begin
                            if IsNullGuid("Record GUID") then
                                "Record GUID" := CreateGuid;
                            Validate("Table Relation", OSynchSetupMgt.ShowOSynchFiltersForm("Record GUID", "Table No.", "Master Table No."));
                        end;
                    end;
                }
                field("Outlook Collection"; "Outlook Collection")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the Outlook collection that corresponds to the set of Dynamics 365 records selected for synchronization in the Table No. field.';
                }
                field("No. of Dependencies"; "No. of Dependencies")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of dependent entities which must be synchronized. If these entities are synchronized, the synchronization process is considered to be completed successfully for the current entity. You assign these dependent entities on the Outlook Synch. Dependency table.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Fields")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Fields';
                    Image = OutlookSyncFields;
                    ToolTip = 'View the fields to be synchronized.';

                    trigger OnAction()
                    begin
                        ShowElementFields;
                    end;
                }
                action(Dependencies)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dependencies';
                    ToolTip = 'View records that must be synchronized before dependent records, such as a customer record that must be synchronized before a contact record.';

                    trigger OnAction()
                    begin
                        ShowDependencies;
                    end;
                }
            }
        }
    }

    var
        OSynchSetupMgt: Codeunit "Outlook Synch. Setup Mgt.";
}

