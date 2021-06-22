page 5305 "Outlook Synch. User Setup"
{
    Caption = 'Outlook Synch. User Setup';
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Outlook Synch. User Setup";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "User Lookup";
                    ToolTip = 'Specifies the ID of a user who uses the Windows Server Authentication to log on to Dynamics 365 to access the current database. In Dynamics 365 the user ID consists of only a user name.';
                }
                field("Synch. Entity Code"; "Synch. Entity Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the synchronization entity. The program copied this code from the Code field of the Outlook Synch. Entity table.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies a brief description of the synchronization entity. The program copies this description from the Description field of the Outlook Synch. Entity table. This field is filled in when you enter a code in the Synch. Entity Code field.';
                }
                field("No. of Elements"; "No. of Elements")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the collections which were selected for the synchronization. The user defines these collections on the Outlook Synch. Setup Details page.';
                }
                field(Condition; Condition)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the criteria for defining a set of specific entries to use in the synchronization process. This filter is applied to the table you specified in the Table No. field. For this filter you can use only the CONST and FILTER options.';

                    trigger OnAssistEdit()
                    begin
                        OSynchEntity.Get("Synch. Entity Code");
                        Condition := CopyStr(OSynchSetupMgt.ShowOSynchFiltersForm("Record GUID", OSynchEntity."Table No.", 0), 1, MaxStrLen(Condition));
                    end;
                }
                field("Synch. Direction"; "Synch. Direction")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the direction of the synchronization for the current entry. The following options are available:';
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
            group(Setup)
            {
                Caption = '&Setup';
                Image = Setup;
                action("S&ynch. Elements")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'S&ynch. Elements';
                    Image = Hierarchy;
                    RunObject = Page "Outlook Synch. Setup Details";
                    RunPageLink = "User ID" = FIELD("User ID"),
                                  "Synch. Entity Code" = FIELD("Synch. Entity Code"),
                                  "Outlook Collection" = FILTER(<> '');
                    ToolTip = 'Start the Outlook synchronization.';

                    trigger OnAction()
                    begin
                        CalcFields("No. of Elements");
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
                    begin
                        OSynchEntity.Get("Synch. Entity Code");
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
        OSynchEntity: Record "Outlook Synch. Entity";
        OSynchSetupMgt: Codeunit "Outlook Synch. Setup Mgt.";
}

