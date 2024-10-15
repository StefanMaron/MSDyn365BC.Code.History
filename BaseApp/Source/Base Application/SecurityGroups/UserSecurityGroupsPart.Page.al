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
    begin
        Refresh();
    end;

    internal procedure Refresh()
    var
        SecurityGroup: Codeunit "Security Group";
    begin
        SecurityGroup.GetMembers(Rec);
    end;
}

