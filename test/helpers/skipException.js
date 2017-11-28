export default async promise => {
  try {
    await promise;
  } catch (error) {
    return;
  }
};
