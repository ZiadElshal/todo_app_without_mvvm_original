import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:todo_app/app_colors.dart';
import 'package:todo_app/custom_snack_bar.dart';
import 'package:todo_app/firebase_utils.dart';
import 'package:todo_app/providers/app_config_provider.dart';
import 'package:todo_app/providers/auth_user_provider.dart';
import 'package:todo_app/providers/list_provider.dart';
import 'package:todo_app/model/task.dart';
import 'package:todo_app/task_list/edit_task_screen.dart';

class TaskListItem extends StatefulWidget {
  Task task;

  TaskListItem({required this.task});

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem> {
  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<AppConfigProvider>(context);
    var listProvider = Provider.of<ListProvider>(context);
    var authProvider = Provider.of<AuthUserProvider>(context);
    String? uId = authProvider.currentUser!.id;

    return Container(
      margin: EdgeInsets.all(12),
      child: Slidable(
        // The start action pane is the one at the left or the top side.
        startActionPane: ActionPane(
          extentRatio: 0.52,
          motion: StretchMotion(),
          children: [
            SlidableAction(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                bottomLeft: Radius.circular(25),
              ),
              onPressed: (context){
                // Temporary store the task to restore it later
                final deletedTask = widget.task;

                ///delete task from firebase
                FirebaseUtils.deleteTaskFromFireStore(widget.task, authProvider.currentUser!.id!)
                    .then((value){   //for online
                  print("Task Deleted Successfully");
                  listProvider.getAllTasksFromFireStore(authProvider.currentUser!.id!);
                })
                    .timeout(Duration(seconds: 1),  //for offline
                onTimeout: (){
                      print("Task Deleted Successfully");
                      listProvider.getAllTasksFromFireStore(authProvider.currentUser!.id!);
                }
                );

                /// Show snack bar with undo option
                CustomSnackBar(
                    scaffoldCtx: this.context,
                    title: widget.task.title ,
                    message: "Deleted Successfully.",
                    icon: Icon(Icons.check_circle_outline_rounded, color: AppColors.whiteColor,),

                    labelTextButton: "UNDO",
                    deletedTask: widget.task,
                    onPressed: (){
                      FirebaseUtils.addTaskToFireStore(deletedTask, authProvider.currentUser!.id!)
                          .then((value) {
                        print("Task Restored Successfully");
                        listProvider.getAllTasksFromFireStore(authProvider.currentUser!.id!);
                      });
                    },
                ).showSnackBar();
              },
              backgroundColor: AppColors.redColor,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',

            ),
            SlidableAction(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
              onPressed: (context){
                ///edit task
                Navigator.of(context).pushNamed(EditTaskScreen.routeName,
                arguments: Task(title: widget.task.title, description: widget.task.description, dateTime: widget.task.dateTime)
                );
              },
              backgroundColor: Color(0xFF21B7CA),
              foregroundColor: Colors.white,
              icon: Icons.edit_note_rounded,
              label: 'Edit',
            ),
          ],
        ),

        child: Container(
            //margin: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: provider.appTheme == ThemeMode.light
                  ? AppColors.whiteColor
                  : AppColors.primaryDarkColor,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ///vertical line
                Container(
                  margin: EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: widget.task.isDone
                        ? AppColors.greenColor
                        : AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  height: MediaQuery.of(context).size.height * 0.09,
                  width: MediaQuery.of(context).size.height * 0.005,
                ),

                ///task name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.task.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: widget.task.isDone
                                ? AppColors.greenColor
                                : AppColors.primaryColor,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            color: provider.appTheme == ThemeMode.light
                                ? AppColors.blackColor
                                : AppColors.whiteColor,
                          ),
                          Flexible(
                            child: Text(widget.task.description,
                                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                      color: provider.appTheme == ThemeMode.light
                                          ? AppColors.blackColor
                                          : AppColors.whiteColor,
                                    ),
                              overflow: TextOverflow.ellipsis,
                            ),

                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ///check button
                InkWell(
                  onTap: () {
                    // Update the task locally
                    widget.task.isDone = !widget.task.isDone;

                    // Update task in Firebase
                    FirebaseUtils.updateTaskIsDoneInFireStore(widget.task, authProvider.currentUser!.id!,);

                    // Update the UI
                    setState(() {});
                  },
                  child: widget.task.isDone == true ?
                  /// Done text
                  Text(
                    widget.task.isDone ? "Done!   " : "", // Display "Done!" only if the task is done
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.greenColor
                    ),
                  ) :
                  Container(
                    margin: EdgeInsets.all(25),
                    padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.height * 0.005,
                        horizontal: MediaQuery.of(context).size.height * 0.022),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.check,
                      color: AppColors.whiteColor,
                      size: 30,
                    ),
                  ),
                ),

              ],
            )
        ),
      ),
    );
  }
}
