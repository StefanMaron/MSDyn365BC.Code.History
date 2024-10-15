table 17374 "Staff List Order Line"
{
    Caption = 'Staff List Order Line';

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Staff List Order Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,Position,Org. Unit';
            OptionMembers = " ",Position,"Org. Unit";
        }
        field(4; "Code"; Code[20])
        {
            Caption = 'Code';
            TableRelation = IF (Type = CONST("Org. Unit"),
                                Action = CONST(Approve)) "Organizational Unit" WHERE(Type = CONST(Unit),
                                                                                    Status = CONST(Open))
            ELSE
            IF (Type = CONST("Org. Unit"),
                                                                                             Action = FILTER(Reopen | Close | Rename)) "Organizational Unit" WHERE(Type = CONST(Unit),
                                                                                                                                                              Status = CONST(Approved))
            ELSE
            IF (Type = CONST(Position),
                                                                                                                                                                       Action = CONST(Approve)) Position WHERE(Status = CONST(Planned))
            ELSE
            IF (Type = CONST(Position),
                                                                                                                                                                                Action = FILTER(Reopen | Close)) Position WHERE(Status = CONST(Approved));

            trigger OnValidate()
            begin
                case Type of
                    Type::"Org. Unit":
                        begin
                            OrganizationalUnit.Get(Code);
                            OrganizationalUnit.TestField(Blocked, false);
                            case Action of
                                Action::Approve:
                                    OrganizationalUnit.TestField(Status, OrganizationalUnit.Status::Open);
                                Action::Reopen:
                                    OrganizationalUnit.TestField(Status, OrganizationalUnit.Status::Approved);
                                Action::Close:
                                    OrganizationalUnit.TestField(Status, OrganizationalUnit.Status::Approved);
                                Action::Rename:
                                    OrganizationalUnit.TestField(Status, OrganizationalUnit.Status::Approved);
                            end;
                            Name := OrganizationalUnit.Name;
                        end;
                    Type::Position:
                        begin
                            Position.Get(Code);
                            case Action of
                                Action::Approve:
                                    Position.TestField(Status, Position.Status::Planned);
                                Action::Reopen:
                                    Position.TestField(Status, Position.Status::Approved);
                                Action::Close:
                                    Position.TestField(Status, Position.Status::Approved);
                                Action::Rename:
                                    Error(Text001, Action, Type);
                            end;
                            Name := CopyStr(Position."Job Title Name" + '/' + Position."Org. Unit Name", 1, MaxStrLen(Name));
                        end;
                end;
            end;
        }
        field(5; Name; Text[50])
        {
            Caption = 'Name';
            Editable = false;
        }
        field(6; "Action"; Option)
        {
            Caption = 'Action';
            OptionCaption = 'Approve,Reopen,Close,Rename';
            OptionMembers = Approve,Reopen,Close,Rename;
        }
        field(7; "New Name"; Text[50])
        {
            Caption = 'New Name';

            trigger OnValidate()
            begin
                if "New Name" <> '' then
                    TestField(Action, Action::Reopen);
            end;
        }
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        GetHeader;
        StaffListOrderHeader.TestField(Status, StaffListOrderHeader.Status::Open);
    end;

    trigger OnInsert()
    begin
        GetHeader;
        StaffListOrderHeader.TestField(Status, StaffListOrderHeader.Status::Open);
    end;

    trigger OnModify()
    begin
        GetHeader;
        StaffListOrderHeader.TestField(Status, StaffListOrderHeader.Status::Open);
    end;

    var
        OrganizationalUnit: Record "Organizational Unit";
        Position: Record Position;
        StaffListOrderHeader: Record "Staff List Order Header";
        Text001: Label 'Action %1 should not be used for %2.';

    [Scope('OnPrem')]
    procedure GetHeader()
    begin
        if StaffListOrderHeader."No." = '' then
            StaffListOrderHeader.Get("Document No.");
    end;

    [Scope('OnPrem')]
    procedure ShowComments()
    var
        HROrderCommentLine: Record "HR Order Comment Line";
        HROrderCommentLines: Page "HR Order Comment Lines";
    begin
        TestField("Document No.");
        TestField("Line No.");
        HROrderCommentLine.SetRange("Table Name", HROrderCommentLine."Table Name"::"SL Order");
        HROrderCommentLine.SetRange("No.", "Document No.");
        HROrderCommentLine.SetRange("Line No.", "Line No.");
        HROrderCommentLines.SetTableView(HROrderCommentLine);
        HROrderCommentLines.RunModal;
    end;
}

