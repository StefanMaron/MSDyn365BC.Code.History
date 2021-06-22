page 9070 "Accounting Services Activities"
{
    Caption = 'Accounting Services';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Accounting Services Cue";

    layout
    {
        area(content)
        {
            cuegroup(Documents)
            {
                Caption = 'Documents';
                field("My Incoming Documents"; "My Incoming Documents")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies incoming documents that are assigned to you.';
                }
                field("Ongoing Sales Invoices"; "Ongoing Sales Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Sales Invoice List";
                    ToolTip = 'Specifies sales invoices that are not posted or only partially posted.';
                }
            }
            cuegroup(Camera)
            {
                Caption = 'Camera';
                Visible = HasCamera;

                actions
                {
                    action(CreateIncomingDocumentFromCamera)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create Incoming Doc. from Camera';
                        Image = TileCamera;
                        ToolTip = 'Specifies if you want to create an incoming document, by taking a photo of the document with your mobile device camera. The photo will be attached to the new document.';

                        trigger OnAction()
                        var
                            IncomingDocument: Record "Incoming Document";
                            InStr: InStream;
                        begin
                            if not HasCamera then
                                exit;

                            Camera.SetQuality(100); // 100%
                            Camera.RunModal();
                            if Camera.HasPicture() then begin
                                Camera.GetPicture(InStr);
                                IncomingDocument.CreateIncomingDocument(InStr, 'Incoming Document Picture');
                            end;
                            Clear(Camera);
                            CurrPage.Update;
                        end;
                    }
                }
            }
            cuegroup(Approvals)
            {
                Caption = 'Approvals';
                field("Requests to Approve"; "Requests to Approve")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies requests for certain accounting activities that you must approve for other users before they can proceed.';
                }
            }
            cuegroup("My User Tasks")
            {
                Caption = 'My User Tasks';
                field("UserTaskManagement.GetMyPendingUserTasksCount"; UserTaskManagement.GetMyPendingUserTasksCount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pending User Tasks';
                    Image = Checklist;
                    ToolTip = 'Specifies the number of pending tasks that are assigned to you or to a group that you are a member of.';

                    trigger OnDrillDown()
                    var
                        UserTaskList: Page "User Task List";
                    begin
                        UserTaskList.SetPageToShowMyPendingUserTasks;
                        UserTaskList.Run;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;

        SetRange("User ID Filter", UserId);

        HasCamera := Camera.IsAvailable();
    end;

    var
        UserTaskManagement: Codeunit "User Task Management";
        Camera: Page Camera;
        [InDataSet]
        HasCamera: Boolean;
}

