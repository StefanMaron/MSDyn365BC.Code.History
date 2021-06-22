codeunit 3054 DotNet_Group
{

    trigger OnRun()
    begin
    end;

    var
        DotNetGroup: DotNet Group;

    procedure Captures(var DotNet_CaptureCollection: Codeunit DotNet_CaptureCollection)
    var
        DotNetCaptures: DotNet CaptureCollection;
    begin
        DotNetCaptures := DotNetGroup.Captures;
        DotNet_CaptureCollection.SetCaptureCollection(DotNetCaptures);
    end;

    procedure Index(): Integer
    begin
        exit(DotNetGroup.Index);
    end;

    procedure Length(): Integer
    begin
        exit(DotNetGroup.Length);
    end;

    procedure Name(): Text
    begin
        exit(DotNetGroup.Name);
    end;

    procedure Success(): Boolean
    begin
        exit(DotNetGroup.Success);
    end;

    procedure Value(): Text
    begin
        exit(DotNetGroup.Value);
    end;

    procedure Equals(var DotNet_Group: Codeunit DotNet_Group): Boolean
    var
        DotNetGroup2: DotNet Match;
    begin
        DotNet_Group.GetGroup(DotNetGroup2);
        exit(DotNetGroup.Equals(DotNetGroup2));
    end;

    procedure GetHashCode(): Integer
    begin
        exit(DotNetGroup.GetHashCode());
    end;

    procedure IsDotNetNull(): Boolean
    begin
        exit(IsNull(DotNetGroup));
    end;

    [Scope('OnPrem')]
    procedure GetGroup(var DotNetGroup2: DotNet Group)
    begin
        DotNetGroup2 := DotNetGroup;
    end;

    [Scope('OnPrem')]
    procedure SetGroup(var DotNetGroup2: DotNet Group)
    begin
        DotNetGroup := DotNetGroup2;
    end;
}

