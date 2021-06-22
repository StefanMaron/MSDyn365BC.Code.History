page 5300 "Outlook Synch. Entity"
{
    Caption = 'Outlook Synch. Entity';
    PageType = ListPlus;
    SourceTable = "Outlook Synch. Entity";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a unique identifier for each entry in the Outlook Synch. Entity table.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a short description of the synchronization entity that you create.';
                }
                field("Table No."; "Table No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the Dynamics 365 table that is to be synchronized with an Outlook item.';

                    trigger OnValidate()
                    begin
                        TableNoOnAfterValidate;
                    end;
                }
                field("Table Caption"; "Table Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the Dynamics 365 table to synchronize. The program fills in this field every time you specify a table number in the Table No. field.';
                }
                field(Condition; Condition)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the criteria for defining a set of specific entries to use in the synchronization process. This filter is applied to the table you specified in the Table No. field. For this filter type, you will only be able to define Dynamics 365 filters of the types CONST and FILTER.';

                    trigger OnAssistEdit()
                    begin
                        Condition := CopyStr(OSynchSetupMgt.ShowOSynchFiltersForm("Record GUID", "Table No.", 0), 1, MaxStrLen(Condition));
                    end;
                }
                field("Outlook Item"; "Outlook Item")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the Outlook item that corresponds to the Dynamics 365 table which you specified in the Table No. field.';

                    trigger OnValidate()
                    begin
                        OutlookItemOnAfterValidate;
                    end;
                }
            }
            part(SynchEntityElements; "Outlook Synch. Entity Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Synch. Entity Code" = FIELD(Code);
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
        area(navigation)
        {
            group("S&ynch. Entity")
            {
                Caption = 'S&ynch. Entity';
                Image = OutlookSyncFields;
                action("Fields")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Fields';
                    Image = OutlookSyncFields;
                    ToolTip = 'View the fields to be synchronized.';

                    trigger OnAction()
                    begin
                        ShowEntityFields;
                    end;
                }
                action("Reset to Defaults")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reset to Defaults';
                    Ellipsis = true;
                    Image = Restore;
                    ToolTip = 'Insert the default information.';

                    trigger OnAction()
                    var
                        OutlookSynchSetupDefaults: Codeunit "Outlook Synch. Setup Defaults";
                    begin
                        OutlookSynchSetupDefaults.ResetEntity(Code);
                    end;
                }
                action("Register in Change Log &Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Register in Change Log &Setup';
                    Ellipsis = true;
                    Image = ImportLog;
                    ToolTip = 'Activate the change log to enable tracking of the changes that you made to the synchronization entities.';

                    trigger OnAction()
                    var
                        OSynchEntity: Record "Outlook Synch. Entity";
                    begin
                        OSynchEntity := Rec;
                        OSynchEntity.SetRecFilter;
                        REPORT.Run(REPORT::"Outlook Synch. Change Log Set.", true, false, OSynchEntity);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        OutlookSynchSetupDefaults: Codeunit "Outlook Synch. Setup Defaults";
    begin
        OutlookSynchSetupDefaults.InsertOSynchDefaults;
    end;

    var
        OSynchSetupMgt: Codeunit "Outlook Synch. Setup Mgt.";

    local procedure TableNoOnAfterValidate()
    begin
        CurrPage.Update;
    end;

    local procedure OutlookItemOnAfterValidate()
    begin
        CurrPage.Update;
    end;
}

