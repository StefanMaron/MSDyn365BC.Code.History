page 20360 "Use Case Archival Log Entries"
{
    Caption = 'Use Case Archival Log Entries';
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    SourceTable = "Use Case Archival Log Entry";
    ModifyAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = true;
    RefreshOnActivate = true;
    layout
    {
        area(Content)
        {
            repeater(Group1)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ToolTip = 'Specifies the Entry No. of the log entry.';
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the Description of the use case.';
                    ApplicationArea = Basic, Suite;
                }
                field(Version; Rec.Version)
                {
                    ToolTip = 'Specifies the version of the use case.';
                    ApplicationArea = Basic, Suite;
                }
                field("Log Date-Time"; Rec."Log Date-Time")
                {
                    ToolTip = 'Specifies the log Date-Time of archival.';
                    ApplicationArea = Basic, Suite;
                }
                field("Active Version"; Rec."Active Version")
                {
                    ToolTip = 'Specifies whether this version of use case is active or not.';
                    ApplicationArea = Basic, Suite;
                }
                field("Changed by"; Rec."Changed by")
                {
                    ToolTip = 'Specifies whether use case was changed by Partner or Microsoft.';
                    ApplicationArea = Basic, Suite;
                }
                field("User ID"; Rec."User ID")
                {
                    ToolTip = 'Specifies the USERID who has released the use case.';
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ShowUseCaseAsJson)
            {
                Caption = 'Show Configuration File.';
                ApplicationArea = Basic, Suite;
                Image = ShowSelected;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Downloads the configuration file in the form of Json.';
                trigger OnAction();
                var
                    UseCaseArchivalMgmt: Codeunit "Use Case Archival Mgmt.";
                begin
                    UseCaseArchivalMgmt.ShowConfigurationFile(Rec);
                end;
            }
            action(RestoreUseCase)
            {
                Caption = 'Restore this version.';
                ApplicationArea = Basic, Suite;
                Image = Restore;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Restore this version as a active use case.';
                trigger OnAction();
                var
                    UseCaseArchivalMgmt: Codeunit "Use Case Archival Mgmt.";
                begin
                    UseCaseArchivalMgmt.RestoreArchivalToUse(Rec);
                end;
            }
        }
    }
}