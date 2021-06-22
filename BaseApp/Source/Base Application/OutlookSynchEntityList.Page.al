page 5302 "Outlook Synch. Entity List"
{
    Caption = 'Outlook Synchronization Entities';
    CardPageID = "Outlook Synch. Entity";
    Editable = false;
    PageType = List;
    SourceTable = "Outlook Synch. Entity";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
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
                field("Table Caption"; "Table Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the Dynamics 365 table to synchronize. The program fills in this field every time you specify a table number in the Table No. field.';
                }
                field("Outlook Item"; "Outlook Item")
                {
                    ApplicationArea = Basic, Suite;
                    Lookup = false;
                    ToolTip = 'Specifies the name of the Outlook item that corresponds to the Dynamics 365 table which you specified in the Table No. field.';
                    Visible = false;
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
                    RunObject = Page "Outlook Synch. Fields";
                    RunPageLink = "Synch. Entity Code" = FIELD(Code),
                                  "Element No." = CONST(0);
                    ToolTip = 'View the fields to be synchronized.';
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
}

