
fig = uifigure;

g = uigridlayout(fig, [2,1]);
g.RowHeight = {'5x', '1x'};
g.ColumnWidth = {'1x'};

p1 = uipanel(g);
p1.Layout.Row = 1;
p1.Layout.Column = 1;
p1_inner = uigridlayout(p1, [1,1], 'Padding', 0);

p2 = uipanel(g);
p2.Layout.Row = 2;
p2.Layout.Column = 1;
p2_inner = uigridlayout(p2, [1,1], 'Padding', 0);



tree = uitree(p1_inner);

task1 = uitreenode(tree, "Text", "Task 1");

task1a = uitreenode(task1, "Text", "Task 1a");

sld = uislider(p2_inner,"Limits",[1 100],"Enable","off");
