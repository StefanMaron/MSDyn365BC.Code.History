codeunit 3052 DotNet_Match
{

    trigger OnRun()
    begin
    end;

    var
        DotNetMatch: DotNet Match;

    procedure Groups(var DotNet_GroupCollection: Codeunit DotNet_GroupCollection)
    var
        DotNetGroups: DotNet GroupCollection;
    begin
        DotNetGroups := DotNetMatch.Groups;
        DotNet_GroupCollection.SetGroupCollection(DotNetGroups);
    end;

    procedure Index(): Integer
    begin
        exit(DotNetMatch.Index);
    end;

    procedure Length(): Integer
    begin
        exit(DotNetMatch.Length);
    end;

    procedure Name(): Text
    begin
        exit(DotNetMatch.Name);
    end;

    procedure Success(): Boolean
    begin
        exit(DotNetMatch.Success);
    end;

    procedure Value(): Text
    begin
        exit(DotNetMatch.Value);
    end;

    procedure Equals(var DotNet_Match: Codeunit DotNet_Match): Boolean
    var
        DotNetMatch2: DotNet Match;
    begin
        DotNet_Match.GetDotNetMatch(DotNetMatch2);
        exit(DotNetMatch.Equals(DotNetMatch2));
    end;

    procedure GetHashCode(): Integer
    begin
        exit(DotNetMatch.GetHashCode());
    end;

    procedure NextMatch(var NextDotNet_Match: Codeunit DotNet_Match)
    var
        NextDotNetMatch: DotNet Match;
    begin
        NextDotNetMatch := DotNetMatch.NextMatch();
        NextDotNet_Match.SetDotNetMatch(NextDotNetMatch);
    end;

    procedure Result(Replacement: Text): Text
    begin
        exit(DotNetMatch.Result(Replacement));
    end;

    procedure IsDotNetNull(): Boolean
    begin
        exit(IsNull(DotNetMatch));
    end;

    [Scope('OnPrem')]
    procedure GetDotNetMatch(var DotNetMatch2: DotNet Match)
    begin
        DotNetMatch2 := DotNetMatch;
    end;

    [Scope('OnPrem')]
    procedure SetDotNetMatch(var DotNetMatch2: DotNet Match)
    begin
        DotNetMatch := DotNetMatch2;
    end;
}

