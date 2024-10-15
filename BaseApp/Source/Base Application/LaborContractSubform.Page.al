page 17367 "Labor Contract Subform"
{
    Caption = 'Lines';
    PageType = ListPart;
    SourceTable = "Labor Contract Line";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the record.';
                }
                field("Operation Type"; "Operation Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Supplement No."; "Supplement No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Order No."; "Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related order was created.';
                }
                field("Order Date"; "Order Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related order was created.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the activity in question. ';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day of the activity in question. ';
                }
                field("Position Rate"; "Position Rate")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Position No."; "Position No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Salary Terms"; "Salary Terms")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Vacation Terms"; "Vacation Terms")
                {
                    Visible = false;
                }
                field("Trial Period Start Date"; "Trial Period Start Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Trial Period End Date"; "Trial Period End Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Trial Period Description"; "Trial Period Description")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Dismissal Reason"; "Dismissal Reason")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Dismissal Document"; "Dismissal Document")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Territorial Conditions"; "Territorial Conditions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Special Conditions"; "Special Conditions")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Record of Service Reason"; "Record of Service Reason")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Record of Service Additional"; "Record of Service Additional")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Service Years Reason"; "Service Years Reason")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Create Contract Terms")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Contract Terms';
                    Image = CreateDocument;

                    trigger OnAction()
                    begin
                        CreateContractTerms;
                    end;
                }
                action("Approve Line")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Approve Line';
                    Image = Approve;
                    ShortCutKey = 'F9';

                    trigger OnAction()
                    begin
                        Approve;
                    end;
                }
                action("Terminate Combination")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Terminate Combination';
                    Image = Cancel;

                    trigger OnAction()
                    begin
                        TerminateCombination;
                    end;
                }
                action("Cancel Line Approval")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cancel Line Approval';
                    Image = CancelLine;

                    trigger OnAction()
                    begin
                        CancelLineApproval;
                    end;
                }
            }
            group("P&rint")
            {
                Caption = 'P&rint';
                Image = Print;
                action("Line Order")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Line Order';
                    Image = Line;

                    trigger OnAction()
                    begin
                        PrintOrder;
                    end;
                }
            }
            group("L&ine")
            {
                Caption = 'L&ine';
                Image = Line;
                action("Contract Terms")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contract Terms';
                    Image = CheckList;

                    trigger OnAction()
                    begin
                        ShowContractTerms;
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    ToolTip = 'View or add comments for the record.';

                    trigger OnAction()
                    begin
                        ShowComments;
                    end;
                }
            }
        }
    }

    var
        LaborContractMgt: Codeunit "Labor Contract Management";

    [Scope('OnPrem')]
    procedure Approve()
    begin
        LaborContractMgt.ConfirmApprove(Rec);
    end;

    [Scope('OnPrem')]
    procedure CreateContractTerms()
    begin
        LaborContractMgt.CreateContractTerms(Rec, false);
    end;

    [Scope('OnPrem')]
    procedure TerminateCombination()
    begin
        LaborContractMgt.TerminateCombination(Rec);
    end;

    [Scope('OnPrem')]
    procedure CancelLineApproval()
    begin
        LaborContractMgt.ConfirmCancelApproval(Rec);
    end;
}

