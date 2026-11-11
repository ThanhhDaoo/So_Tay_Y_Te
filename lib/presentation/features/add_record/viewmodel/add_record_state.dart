abstract class AddRecordState {
  const AddRecordState();
}

class AddRecordInitial extends AddRecordState {}

class AddRecordSubmitting extends AddRecordState {}

class AddRecordSuccess extends AddRecordState {}

class AddRecordFailure extends AddRecordState {
  final String error;
  const AddRecordFailure(this.error);
}
