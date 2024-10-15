namespace System.Security.AccessControl;

page 9848 "User Security Groups Part"
{
    Caption = 'Security Groups';
    PageType = ListPart;
    PopulateAllFields = true;
    SourceTable = "Security Group Member Buffer";
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(SecurityGroupCode; Rec."Security Group Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Code';
                    ToolTip = 'Specifies the security group code.';

                    trigger OnDrillDown()
                    var
                        SecurityGroupBuffer: Record "Security Group Buffer";
                        SecurityGroups: Page "Security Groups";
                    begin
                        SecurityGroupBuffer.SetRange(Code, Rec."Security Group Code");
                        SecurityGroups.SetTableView(SecurityGroupBuffer);
                        SecurityGroups.Run();
                    end;
                }
                field("Security Group Name"; Rec."Security Group Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the security group.';
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        SecurityGroup: Codeunit "Security Group";
    begin
        if not IsInitializedByCaller then
            SecurityGroup.GetMembers(Rec);
    end;

    internal procedure GetSourceRecord(var SecurityGroupMemberBuffer: Record "Security Group Member Buffer")
    begin
        IsInitializedByCaller := true;
        SecurityGroupMemberBuffer.Copy(Rec, true);
    end;

    var
        IsInitializedByCaller: Boolean;
}

